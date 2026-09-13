pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland
import qs.configs

Singleton {
    id: service

    property string currentTime: ""
    property string currentDate: ""
    property string statusMessage: ""
    property bool isAuthenticating: false
    property string pendingPassword: ""
    property bool isLocked: false
    property bool isDimmed: false

    readonly property int idleTimeoutSeconds: Math.max(0, Config.idleLockTimeout) * 60
    readonly property int fadeTime: (typeof Config.fadeDuration === "number" && Config.fadeDuration >= 300) ? Config.fadeDuration : 1000

    property bool lidStateKnown: false
    property bool lidClosed: false

    // Hardware udev event monitor
    Process {
        id: lidEventProcess
        command: ["udevadm", "monitor", "--kernel", "--subsystem-match=button", "--property"]
        stdout: SplitParser {
            onRead: data => {
                const event = data.trim().toLowerCase();
                if (Config.lockOnLidClose && (event.includes("switch_state=1") || (event.includes("button/lid") && event.includes("close"))))
                    service.lock();
            }
        }
        running: true
    }

    // ACPI /proc fallback poller
    Process {
        id: lidStateProcess
        command: ["sh", "-c", "for state in /proc/acpi/button/lid/*/state; do [ -r \"$state\" ] && cat \"$state\"; done"]
        stdout: SplitParser {
            onRead: data => {
                const closed = data.trim().includes("closed");
                if (service.lidStateKnown && closed && !service.lidClosed && Config.lockOnLidClose) {
                    service.lock();
                }
                service.lidClosed = closed;
                service.lidStateKnown = true;
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!lidStateProcess.running)
                lidStateProcess.running = true;
        }
    }

    // Timer following the gradual fade curtain
    Timer {
        id: postFadeLockTimer
        interval: service.fadeTime + 50
        repeat: false
        onTriggered: {
            service.isLocked = true;
            pendingPassword = "";
            statusMessage = "";
            if (Config.fadeToMonitorOff)
                Quickshell.execDetached(["niri", "msg", "action", "power-off-monitors"]);
            service.isDimmed = false;
        }
    }

    function triggerFadeAndLock(): void {
        if (service.isDimmed || service.isLocked)
            return;
        service.isDimmed = true;
        Quickshell.execDetached(["sh", "-c", "if command -v brightnessctl >/dev/null 2>&1; then brightnessctl -s -q set 0% -t " + service.fadeTime + "; fi"]);
        postFadeLockTimer.restart();
    }

    function wakeScreen(): void {
        postFadeLockTimer.stop();
        if (service.isDimmed) {
            service.isDimmed = false;
            Quickshell.execDetached(["sh", "-c", "if command -v brightnessctl >/dev/null 2>&1; then brightnessctl -r -q -t 150 || brightnessctl -q set 80% -t 150; fi"]);
        }
    }

    // Instant lock for lid switch / sleep events to prevent unlocked flash
    function lockImmediately(): void {
        postFadeLockTimer.stop();
        service.isDimmed = false;
        service.isLocked = true;
        pendingPassword = "";
        statusMessage = "";
        if (Config.fadeToMonitorOff)
            Quickshell.execDetached(["niri", "msg", "action", "power-off-monitors"]);
    }

    // systemd-logind Sleep Delay Inhibitor & PrepareForSleep listener
    Process {
        id: sleepInhibitorProcess
        command: ["python3", "-u", "-c", `
import dbus
from dbus.mainloop.glib import DBusGMainLoop
from gi.repository import GLib
import os, sys, threading

DBusGMainLoop(set_as_default=True)
bus = dbus.SystemBus()
login_obj = bus.get_object("org.freedesktop.login1", "/org/freedesktop/login1")
login_mgr = dbus.Interface(login_obj, "org.freedesktop.login1.Manager")

lock_fd = None

def take_inhibitor():
    global lock_fd
    try:
        fd_obj = login_mgr.Inhibit("sleep", "wisp-shell", "Locking screen before sleep", "delay")
        lock_fd = fd_obj.take()
    except Exception as e:
        sys.stderr.write(f"[SleepInhibitor] Failed to take inhibitor: {e}\\n")

def release_inhibitor():
    global lock_fd
    if lock_fd is not None:
        try:
            os.close(lock_fd)
        except OSError:
            pass
        lock_fd = None

def on_prepare_for_sleep(sleeping):
    if sleeping:
        print("PREPARE_SLEEP", flush=True)
    else:
        take_inhibitor()
        print("WOKE_UP", flush=True)

login_mgr.connect_to_signal("PrepareForSleep", on_prepare_for_sleep)
take_inhibitor()

def stdin_reader():
    for line in sys.stdin:
        if "DONE_LOCKING" in line:
            release_inhibitor()

threading.Thread(target=stdin_reader, daemon=True).start()
GLib.MainLoop().run()
`]
        stdout: SplitParser {
            onRead: data => {
                const line = data.trim();
                if (line.includes("PREPARE_SLEEP")) {
                    if (Config.lockOnLidClose || Config.idleLockTimeout > 0) {
                        service.lockImmediately();
                    }
                    // Signal python to close FD and let systemd proceed to sleep
                    sleepInhibitorProcess.write("DONE_LOCKING\n");
                }
            }
        }
        running: true
    }

    IdleMonitor {
        id: idleMonitor
        enabled: service.idleTimeoutSeconds > 0
        timeout: service.idleTimeoutSeconds
        onIsIdleChanged: {
            if (isIdle) {
                if (!service.isLocked) {
                    service.triggerFadeAndLock();
                }
            } else {
                if (!service.isLocked) {
                    service.wakeScreen();
                } else {
                    Quickshell.execDetached(["sh", "-c", "if command -v brightnessctl >/dev/null 2>&1; then brightnessctl -r -q -t 150 || brightnessctl -q set 80% -t 150; fi"]);
                }
            }
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

    PamContext {
        id: pam
        config: "login"
        user: Config.targetUser

        onPamMessage: {
            if (pam.responseRequired) {
                pam.respond(service.pendingPassword);
                service.pendingPassword = "";
            }
        }

        onCompleted: result => {
            service.isAuthenticating = false;
            service.pendingPassword = "";
            if (result === PamResult.Success) {
                service.statusMessage = "Unlocked";
                service.isLocked = false;
                service.wakeScreen();
            } else {
                service.statusMessage = "Incorrect password";
            }
        }

        onError: error => {
            service.isAuthenticating = false;
            service.pendingPassword = "";
            service.statusMessage = PamError.toString(error);
        }
    }

    function unlock(password: string): void {
        if (!password || isAuthenticating || !Config.targetUser)
            return;
        pendingPassword = password;
        isAuthenticating = true;
        statusMessage = "Unlocking...";
        if (!pam.start()) {
            isAuthenticating = false;
            pendingPassword = "";
            statusMessage = "Could not start authentication";
        }
    }

    function lock(): void {
        pendingPassword = "";
        statusMessage = "";
        service.triggerFadeAndLock();
    }

    property IpcHandler lockIpc: IpcHandler {
        target: "lockscreen"
        function lock(): void {
            service.triggerFadeAndLock();
        }
    }
}
