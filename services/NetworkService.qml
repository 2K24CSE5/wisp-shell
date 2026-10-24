pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    // ── Legacy & Core Properties ──────────────────────────────────────────────
    property bool ethernetConnected: false
    property bool wifiEnabled: false
    property bool wifiConnected: false
    property string connectedWifiSsid: ""
    property var accessPoints: []

    // ── Extended Network Information ──────────────────────────────────────────
    property string connectivity: "unknown" // "full", "limited", "portal", "none", "unknown"
    property bool networkingEnabled: true
    property bool isScanning: false
    property bool isConnecting: false
    property string connectingSsid: ""
    property string lastError: ""
    property string pingLatency: "--"
    property bool isPinging: false

    // Wi-Fi Details
    property string wifiDevice: ""
    property string wifiHwAddr: ""
    property string wifiIp4: ""
    property string wifiGateway: ""
    property string wifiDns: ""
    property string wifiIp6: ""
    property int connectedWifiSignal: 0
    property string connectedWifiSecurity: ""
    property string connectedWifiFreq: ""
    property string connectedWifiRate: ""
    property string connectedWifiBssid: ""

    // Ethernet Details
    property string ethernetDevice: ""
    property string ethernetState: "unavailable"
    property string ethernetName: ""
    property string ethernetHwAddr: ""
    property string ethernetIp4: ""
    property string ethernetGateway: ""
    property string ethernetDns: ""

    // Saved Network Profiles
    property var savedConnections: []

    // ── Debounce Timer for Network Updates ────────────────────────────────────
    property Timer updateDebounceTimer: Timer {
        interval: 150
        repeat: false
        onTriggered: root.poll()
    }

    // ── Real-time NetworkManager Event Monitor ────────────────────────────────
    property Process nmMonitorProc: Process {
        command: ["nmcli", "monitor"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                if (line && line.trim().length > 0) {
                    root.updateDebounceTimer.restart();
                }
            }
        }
        onExited: () => reconnectTimer.restart()
    }

    property Timer reconnectTimer: Timer {
        interval: 3000
        repeat: false
        onTriggered: {
            if (!root.nmMonitorProc.running) {
                root.nmMonitorProc.running = true;
            }
            root.poll();
        }
    }

    // ── Comprehensive Network Data Extractor ──────────────────────────────────
    property Process dataProcess: Process {
        command: ["python3", "-c", `
import subprocess, json

def get_network_data():
    conn = 'unknown'
    try:
        p = subprocess.run(['nmcli', 'networking', 'connectivity', 'check'], capture_output=True, text=True, timeout=2)
        conn = p.stdout.strip() or 'unknown'
    except Exception:
        pass

    net_enabled = True
    try:
        p = subprocess.run(['nmcli', 'networking'], capture_output=True, text=True, timeout=2)
        net_enabled = (p.stdout.strip() == 'enabled')
    except Exception:
        pass

    wifi_radio = False
    try:
        p = subprocess.run(['nmcli', 'radio', 'wifi'], capture_output=True, text=True, timeout=2)
        wifi_radio = (p.stdout.strip() == 'enabled')
    except Exception:
        pass

    devices = []
    try:
        p = subprocess.run(['nmcli', '-t', '-f', 'DEVICE,TYPE,STATE,CONNECTION', 'device'], capture_output=True, text=True, timeout=2)
        for line in p.stdout.strip().split('\\n'):
            if not line: continue
            parts = line.split(':')
            if len(parts) >= 3:
                devices.append({
                    'device': parts[0],
                    'type': parts[1],
                    'state': parts[2],
                    'connection': ':'.join(parts[3:]) if len(parts) > 3 else ''
                })
    except Exception:
        pass

    wifi_info = None
    eth_info = None

    for d in devices:
        dtype = d['type']
        dname = d['device']
        if dtype in ('wifi', 'ethernet'):
            try:
                p = subprocess.run(['nmcli', '-t', '-f', 'GENERAL.DEVICE,GENERAL.TYPE,GENERAL.HWADDR,GENERAL.STATE,GENERAL.CONNECTION,IP4.ADDRESS,IP4.GATEWAY,IP4.DNS,IP6.ADDRESS', 'device', 'show', dname], capture_output=True, text=True, timeout=2)
                info = {'device': dname, 'type': dtype, 'state': d['state'], 'connection': d['connection'], 'ip4': '', 'gateway': '', 'dns': '', 'hwaddr': '', 'ip6': ''}
                for sline in p.stdout.strip().split('\\n'):
                    if not sline or ':' not in sline: continue
                    k, v = sline.split(':', 1)
                    if k == 'GENERAL.HWADDR': info['hwaddr'] = v
                    elif k.startswith('IP4.ADDRESS') and not info['ip4']: info['ip4'] = v
                    elif k == 'IP4.GATEWAY' and not info['gateway']: info['gateway'] = v
                    elif k.startswith('IP4.DNS') and not info['dns']: info['dns'] = v
                    elif k.startswith('IP6.ADDRESS') and not info['ip6']: info['ip6'] = v
                if dtype == 'wifi' and not wifi_info:
                    wifi_info = info
                elif dtype == 'ethernet' and not eth_info:
                    eth_info = info
            except Exception:
                pass

    saved = []
    saved_wifi_names = set()
    try:
        p = subprocess.run(['nmcli', '-t', '-f', 'NAME,TYPE,UUID,AUTOCONNECT', 'connection', 'show'], capture_output=True, text=True, timeout=2)
        for line in p.stdout.strip().split('\\n'):
            if not line: continue
            line = line.replace(r'\\:', '__COLON__')
            parts = line.split(':')
            if len(parts) >= 4:
                name = parts[0].replace('__COLON__', ':')
                ctype = parts[1]
                uuid = parts[2]
                auto = (parts[3] == 'yes')
                if 'wireless' in ctype:
                    saved.append({'name': name, 'type': 'wifi', 'uuid': uuid, 'autoconnect': auto})
                    saved_wifi_names.add(name)
                elif 'ethernet' in ctype:
                    saved.append({'name': name, 'type': 'ethernet', 'uuid': uuid, 'autoconnect': auto})
    except Exception:
        pass

    aps = []
    ap_map = {}
    if wifi_radio:
        try:
            p = subprocess.run(['nmcli', '-t', '-f', 'IN-USE,SSID,SIGNAL,SECURITY,CHAN,FREQ,RATE,BSSID', 'device', 'wifi', 'list', '--rescan', 'no'], capture_output=True, text=True, timeout=3)
            for line in p.stdout.strip().split('\\n'):
                if not line: continue
                line = line.replace(r'\\:', '__COLON__')
                parts = line.split(':')
                if len(parts) >= 8:
                    in_use = (parts[0].strip() == '*')
                    ssid = parts[1].replace('__COLON__', ':').strip()
                    if not ssid or ssid == '--':
                        continue
                    try:
                        signal = int(parts[2].strip())
                    except Exception:
                        signal = 0
                    sec = parts[3].replace('__COLON__', ':').strip()
                    chan = parts[4].strip()
                    freq = parts[5].replace('__COLON__', ':').strip()
                    rate = parts[6].replace('__COLON__', ':').strip()
                    bssid = parts[7].replace('__COLON__', ':').strip()
                    band = '5 GHz' if ('5' in freq and 'MHz' in freq and int(freq.split()[0]) > 4000) else '2.4 GHz'
                    req_pwd = bool(sec and sec != '--')
                    is_saved = (ssid in saved_wifi_names)

                    if ssid not in ap_map or in_use or signal > ap_map[ssid]['signal']:
                        ap_map[ssid] = {
                            'ssid': ssid,
                            'connected': in_use,
                            'requiresPassword': req_pwd,
                            'security': sec if sec != '--' else 'Open',
                            'signal': signal,
                            'chan': chan,
                            'freq': freq,
                            'band': band,
                            'rate': rate,
                            'bssid': bssid,
                            'isSaved': is_saved
                        }
            aps = list(ap_map.values())
            aps.sort(key=lambda a: (not a['connected'], -a['signal'], a['ssid'].lower()))
        except Exception:
            pass

    return {
        'connectivity': conn,
        'networkingEnabled': net_enabled,
        'wifiRadio': wifi_radio,
        'wifiDetails': wifi_info,
        'ethernetDetails': eth_info,
        'saved': saved,
        'accessPoints': aps
    }

print(json.dumps(get_network_data()))
`]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!this.text || !this.text.trim())
                    return;
                try {
                    const data = JSON.parse(this.text.trim());
                    root.connectivity = data.connectivity || "unknown";
                    root.networkingEnabled = Boolean(data.networkingEnabled);
                    root.wifiEnabled = Boolean(data.wifiRadio);

                    if (data.wifiDetails) {
                        root.wifiDevice = data.wifiDetails.device || "";
                        root.wifiHwAddr = data.wifiDetails.hwaddr || "";
                        root.wifiConnected = data.wifiDetails.state === "connected";
                        root.connectedWifiSsid = data.wifiDetails.connection || "";
                        root.wifiIp4 = data.wifiDetails.ip4 || "";
                        root.wifiGateway = data.wifiDetails.gateway || "";
                        root.wifiDns = data.wifiDetails.dns || "";
                        root.wifiIp6 = data.wifiDetails.ip6 || "";
                    } else {
                        root.wifiDevice = "";
                        root.wifiHwAddr = "";
                        root.wifiConnected = false;
                        root.connectedWifiSsid = "";
                        root.wifiIp4 = "";
                        root.wifiGateway = "";
                        root.wifiDns = "";
                        root.wifiIp6 = "";
                    }

                    if (data.ethernetDetails) {
                        root.ethernetDevice = data.ethernetDetails.device || "";
                        root.ethernetHwAddr = data.ethernetDetails.hwaddr || "";
                        root.ethernetConnected = data.ethernetDetails.state === "connected";
                        root.ethernetState = data.ethernetDetails.state || "";
                        root.ethernetName = data.ethernetDetails.connection || "";
                        root.ethernetIp4 = data.ethernetDetails.ip4 || "";
                        root.ethernetGateway = data.ethernetDetails.gateway || "";
                        root.ethernetDns = data.ethernetDetails.dns || "";
                    } else {
                        root.ethernetDevice = "";
                        root.ethernetHwAddr = "";
                        root.ethernetConnected = false;
                        root.ethernetState = "unavailable";
                        root.ethernetName = "";
                        root.ethernetIp4 = "";
                        root.ethernetGateway = "";
                        root.ethernetDns = "";
                    }

                    root.savedConnections = data.saved || [];
                    root.accessPoints = data.accessPoints || [];

                    if (root.wifiConnected && root.connectedWifiSsid) {
                        const activeAp = (data.accessPoints || []).find(ap => ap.ssid === root.connectedWifiSsid);
                        if (activeAp) {
                            root.connectedWifiSignal = activeAp.signal || 0;
                            root.connectedWifiSecurity = activeAp.security || "";
                            root.connectedWifiFreq = activeAp.freq || "";
                            root.connectedWifiRate = activeAp.rate || "";
                            root.connectedWifiBssid = activeAp.bssid || "";
                        }
                    }
                } catch (_) {}
            }
        }
    }

    // ── Rescan Process ────────────────────────────────────────────────────────
    property Process rescanProcess: Process {
        command: ["nmcli", "device", "wifi", "rescan"]
        onExited: () => {
            root.isScanning = false;
            root.poll();
        }
    }

    // ── Connection Process ────────────────────────────────────────────────────
    property Process connectProcess: Process {
        stdout: StdioCollector {
            onStreamFinished: {
                root.isConnecting = false;
                root.connectingSsid = "";
                root.poll();
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                const err = this.text ? this.text.trim() : "";
                if (err) {
                    root.lastError = err.replace(/^Error:\s*/i, "");
                }
            }
        }
        onExited: exitCode => {
            root.isConnecting = false;
            root.connectingSsid = "";
            if (exitCode === 0) {
                root.lastError = "";
            }
            root.poll();
        }
    }

    // ── Ping Diagnostic Process ───────────────────────────────────────────────
    property Process pingProcess: Process {
        stdout: StdioCollector {
            onStreamFinished: {
                root.isPinging = false;
                const out = (this.text || "").trim();
                root.pingLatency = out ? out : "Timeout";
            }
        }
        onExited: () => {
            root.isPinging = false;
        }
    }

    // ── Public API Methods ────────────────────────────────────────────────────

    function toggleWifiRadio(): void {
        const nextState = root.wifiEnabled ? "off" : "on";
        Quickshell.execDetached(["nmcli", "radio", "wifi", nextState]);
        root.wifiEnabled = !root.wifiEnabled;
        if (!root.wifiEnabled) {
            root.wifiConnected = false;
            root.connectedWifiSsid = "";
            root.accessPoints = [];
        }
        updateDebounceTimer.restart();
    }

    function toggleNetworking(): void {
        const nextState = root.networkingEnabled ? "off" : "on";
        Quickshell.execDetached(["nmcli", "networking", nextState]);
        root.networkingEnabled = !root.networkingEnabled;
        updateDebounceTimer.restart();
    }

    function disconnectWifi(): void {
        Quickshell.execDetached(["sh", "-c", "nmcli -t -f DEVICE,TYPE,STATE device | awk -F: '$2==\"wifi\" && $3==\"connected\" {print $1}' | xargs -r nmcli device disconnect"]);
        root.wifiConnected = false;
        root.connectedWifiSsid = "";
        updateDebounceTimer.restart();
    }

    function connectWifi(ssid: string): void {
        if (!ssid)
            return;
        root.lastError = "";
        root.isConnecting = true;
        root.connectingSsid = ssid;
        connectProcess.command = ["nmcli", "device", "wifi", "connect", ssid];
        connectProcess.running = true;
    }

    function connectWifiWithPassword(ssid: string, password: string): void {
        if (!ssid)
            return;
        root.lastError = "";
        root.isConnecting = true;
        root.connectingSsid = ssid;
        connectProcess.command = ["nmcli", "device", "wifi", "connect", ssid, "password", password];
        connectProcess.running = true;
    }

    function connectHiddenWifi(ssid: string, password: string, isWpa: bool): void {
        if (!ssid)
            return;
        root.lastError = "";
        root.isConnecting = true;
        root.connectingSsid = ssid;
        if (isWpa && password) {
            connectProcess.command = ["nmcli", "device", "wifi", "connect", ssid, "password", password, "hidden", "yes"];
        } else {
            connectProcess.command = ["nmcli", "device", "wifi", "connect", ssid, "hidden", "yes"];
        }
        connectProcess.running = true;
    }

    function connectSaved(uuid: string): void {
        if (!uuid)
            return;
        root.lastError = "";
        connectProcess.command = ["nmcli", "connection", "up", "uuid", uuid];
        connectProcess.running = true;
    }

    function forgetConnection(uuid: string): void {
        if (!uuid)
            return;
        Quickshell.execDetached(["nmcli", "connection", "delete", "uuid", uuid]);
        updateDebounceTimer.restart();
    }

    function setAutoconnect(uuid: string, auto: bool): void {
        if (!uuid)
            return;
        Quickshell.execDetached(["nmcli", "connection", "modify", uuid, "connection.autoconnect", auto ? "yes" : "no"]);
        updateDebounceTimer.restart();
    }

    function scanWifi(): void {
        root.isScanning = true;
        if (!rescanProcess.running) {
            rescanProcess.running = true;
        }
    }

    function disconnectEthernet(): void {
        if (!root.ethernetDevice)
            return;
        Quickshell.execDetached(["nmcli", "device", "disconnect", root.ethernetDevice]);
        updateDebounceTimer.restart();
    }

    function connectEthernet(): void {
        if (!root.ethernetDevice)
            return;
        Quickshell.execDetached(["nmcli", "device", "connect", root.ethernetDevice]);
        updateDebounceTimer.restart();
    }

    function testPing(): void {
        root.isPinging = true;
        root.pingLatency = "...";
        pingProcess.command = ["sh", "-c", "ping -c 1 -W 2 1.1.1.1 2>/dev/null | grep -o 'time=[0-9.]* ms' | cut -d= -f2 || echo 'Timeout'"];
        pingProcess.running = true;
    }

    function copyToClipboard(text: string): void {
        if (!text)
            return;
        Quickshell.execDetached(["wl-copy", text]);
    }

    function clearError(): void {
        root.lastError = "";
    }

    function poll(): void {
        if (!dataProcess.running) {
            dataProcess.running = true;
        }
    }

    // Periodic fallback poll (every 5 seconds)
    property Timer pollTimer: Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.poll()
    }

    // ── IPC API ───────────────────────────────────────────────────────────────
    property IpcHandler networkIpc: IpcHandler {
        target: "network"
        function toggleWifi(): void {
            root.toggleWifiRadio();
        }
        function toggleAirplane(): void {
            root.toggleNetworking();
        }
        function scan(): void {
            root.scanWifi();
        }
        function disconnect(): void {
            root.disconnectWifi();
        }
        function isConnected(): bool {
            return root.wifiConnected || root.ethernetConnected;
        }
        function getSsid(): string {
            return root.connectedWifiSsid;
        }
    }
}
