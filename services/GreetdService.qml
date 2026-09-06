pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.configs

Singleton {
    id: service

    property string currentTime: ""
    property string currentDate: ""
    property string statusMessage: ""
    property bool isAuthenticating: false
    property bool loginFailed: false
    property var availableSessions: []
    property bool isLoadingSessions: true
    property int selectedSessionIndex: 0
    readonly property var selectedSession: availableSessions[Math.max(0, Math.min(selectedSessionIndex, availableSessions.length - 1))]
    readonly property string defaultUsername: Config.targetUser

    readonly property string greetdSocket: Quickshell.env("GREETD_SOCK") || "/run/greetd.sock"
    readonly property bool isLiveGreetd: Quickshell.env("GREETD_SOCK") !== undefined

    Process {
        id: sessionDiscoveryProc

        stdout: SplitParser {
            onRead: data => {
                try {
                    service.availableSessions = JSON.parse(data);
                    const savedIndex = service.availableSessions.findIndex(session => session.name === Config.selectedSession);
                    service.selectedSessionIndex = savedIndex >= 0 ? savedIndex : 0;
                } catch (error) {
                    service.availableSessions = [];
                    service.statusMessage = "Could not read available sessions";
                }
            }
        }

        onExited: (code, status) => {
            service.isLoadingSessions = false;
            if (code !== 0)
                service.availableSessions = [];
        }

        Component.onCompleted: {
            command = ["python3", "-c", `
import configparser, json, os, shlex, shutil

search_dirs = []
for base in os.environ.get("XDG_DATA_DIRS", "/usr/local/share:/usr/share").split(":"):
    if base:
        search_dirs.extend([os.path.join(base, "wayland-sessions"), os.path.join(base, "xsessions")])
home = os.path.expanduser("~/.local/share")
search_dirs.extend([os.path.join(home, "wayland-sessions"), os.path.join(home, "xsessions")])

sessions = []
seen = set()
for directory in search_dirs:
    try:
        if not os.path.isdir(directory):
            continue
        filenames = sorted(os.listdir(directory))
    except (PermissionError, OSError):
        continue

    for filename in filenames:
        if not filename.endswith(".desktop"):
            continue
        path = os.path.join(directory, filename)
        if path in seen:
            continue
        seen.add(path)
        parser = configparser.ConfigParser(interpolation=None, strict=False)
        parser.optionxform = str
        try:
            with open(path, encoding="utf-8") as session_file:
                parser.read_file(session_file)
            entry = parser["Desktop Entry"]
            if entry.get("Type", "Application") != "Application" or entry.get("Hidden", "false").lower() == "true" or entry.get("NoDisplay", "false").lower() == "true":
                continue
            command = shlex.split(entry.get("Exec", ""))
            command = [part for part in command if not part.startswith("%")]
            if not command or not shutil.which(command[0]):
                continue
            sessions.append({"name": entry.get("Name", os.path.splitext(filename)[0]), "command": command})
        except (KeyError, OSError, ValueError):
            continue

sessions.sort(key=lambda session: session["name"].lower())
print(json.dumps(sessions))
`];
            running = true;
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            const date = new Date();
            service.currentTime = Qt.formatTime(date, "hh:mm");
            service.currentDate = Qt.formatDateTime(date, "dddd, MMMM d");
        }
    }

    Timer {
        id: sessionLaunchTimer
        interval: 350
        repeat: false
        onTriggered: {
            Quickshell.execDetached(["pkill", "-u", "greeter", "-9"]);
            Qt.quit();
        }
    }

    Process {
        id: authProc
        property string stdoutBuffer: ""
        property string stderrBuffer: ""

        stdout: SplitParser {
            onRead: data => {
                authProc.stdoutBuffer += data;
            }
        }

        stderr: SplitParser {
            onRead: data => {
                authProc.stderrBuffer += data;
            }
        }

        onExited: (code, status) => {
            service.isAuthenticating = false;
            const output = [authProc.stdoutBuffer, authProc.stderrBuffer].join("\n").trim();
            authProc.stdoutBuffer = "";
            authProc.stderrBuffer = "";

            if (code === 0) {
                service.statusMessage = "Authenticated. Launching session...";
                sessionLaunchTimer.start();
            } else {
                service.loginFailed = true;
                service.statusMessage = output || "Authentication failed";
            }
        }
    }

    function login(username: string, secret: string): void {
        if (!username || !secret || isAuthenticating || !selectedSession)
            return;

        if (!isLiveGreetd) {
            service.statusMessage = "greetd is not running; start the greeter through greetd";
            return;
        }

        isAuthenticating = true;
        loginFailed = false;
        service.statusMessage = "Authenticating...";

        const sessionCmd = JSON.stringify(selectedSession.command);

        const pyAuthScript = `
import os, sys, socket, json, struct

sock_path = sys.argv[-1] if len(sys.argv) > 1 else os.environ.get("GREETD_SOCK")
if not sock_path:
    print("GREETD_SOCK not set")
    sys.exit(1)

def send_msg(s, obj):
    body = json.dumps(obj).encode("utf-8")
    s.sendall(struct.pack("=I", len(body)) + body)

def recv_msg(s):
    hdr = s.recv(4)
    if not hdr or len(hdr) < 4:
        return None
    length = struct.unpack("=I", hdr)[0]
    payload = b""
    while len(payload) < length:
        chunk = s.recv(length - len(payload))
        if not chunk:
            break
        payload += chunk
    return json.loads(payload.decode("utf-8"))

try:
    client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    client.settimeout(15)
    client.connect(sock_path)

    # 1. Start Session
    send_msg(client, {"type": "create_session", "username": sys.argv[-4]})
    resp = recv_msg(client)

    # 2. Answer prompt / auth challenge
    while resp and resp.get("type") == "auth_message":
        send_msg(client, {"type": "post_auth_message_response", "response": sys.argv[-3]})
        resp = recv_msg(client)

    # 3. Start user desktop with strictly non-empty KEY=VALUE pairs
    if resp and resp.get("type") == "success":
        cmd = json.loads(sys.argv[-2])
        target_username = sys.argv[-4]

        env_map = {
            "XDG_SESSION_TYPE": "wayland",
            "USER": target_username,
            "LOGNAME": target_username,
            "PATH": "/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin",
            "XDG_DATA_DIRS": "/usr/local/share:/usr/share",
        }

        for key in ("XDG_RUNTIME_DIR", "LANG", "LC_ALL", "LC_CTYPE"):
            val = os.environ.get(key)
            if val and 0 < len(val) < 250:
                env_map[key] = val

        env = [f"{k}={v}" for k, v in env_map.items() if k and v]

        send_msg(client, {"type": "start_session", "cmd": cmd, "env": env})
        final_resp = recv_msg(client)

        if final_resp and final_resp.get("type") == "success":
            client.close()
            sys.exit(0)
        else:
            print(final_resp.get("description", "Failed to start session") if final_resp else "No response from greetd")
            sys.exit(1)
    else:
        err = resp.get("description", "Authentication failure") if resp else "Empty daemon response"
        print(err)
        sys.exit(1)
except FileNotFoundError:
    print("greetd socket not found: " + sock_path)
    sys.exit(1)
except Exception as e:
    print(str(e))
    sys.exit(1)
finally:
    try:
        client.close()
    except Exception:
        pass
`;

        authProc.command = ["python3", "-c", pyAuthScript, username, secret, sessionCmd, greetdSocket];
        authProc.running = true;
    }

    function selectSession(index: int): void {
        if (index < 0 || index >= availableSessions.length)
            return;

        selectedSessionIndex = index;
        Config.setSelectedSession(availableSessions[index].name);
    }

    function powerOff(): void {
        Quickshell.execDetached(["systemctl", "poweroff"]);
    }

    function reboot(): void {
        Quickshell.execDetached(["systemctl", "reboot"]);
    }

    function suspend(): void {
        Quickshell.execDetached(["systemctl", "suspend"]);
    }
}
