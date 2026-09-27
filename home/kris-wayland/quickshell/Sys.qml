pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root


    property int  battery: 0
    property bool charging: false
    property bool hasBattery: false


    property bool connected: false
    property bool wifi: false
    property string ssid: ""
    property int  signal: 0

    property int  brightness: 50
    property bool btPowered: false
    property bool dnd: false

    function refresh() { batProc.running = true; netProc.running = true; }

    function refreshExtra() { brightProc.running = true; btProc.running = true; dndProc.running = true; }
    function refreshAll() { refresh(); refreshExtra(); }
    function refreshSoon() { softTimer.restart(); }

    function setBrightness(pct) {
        Quickshell.execDetached(["brightnessctl", "-q", "set", Math.round(pct) + "%"]);
        brightness = pct;
    }
    function toggleWifi() {
        Quickshell.execDetached(["sh", "-c",
            "nmcli radio wifi | grep -q enabled && nmcli radio wifi off || nmcli radio wifi on"]);
        refreshSoon();
    }
    function toggleBt() {
        Quickshell.execDetached(["sh", "-c",
            "bluetoothctl show | grep -q 'Powered: yes' && bluetoothctl power off || bluetoothctl power on"]);
        refreshSoon();
    }
    function toggleDnd() { Quickshell.execDetached(["swaync-client", "-d"]); dnd = !dnd; }

    Component.onCompleted: refreshAll()

    Timer { interval: 30000; running: true; repeat: true; onTriggered: root.refresh() }
    Timer { id: softTimer; interval: 700; onTriggered: root.refreshAll() }

    Process {
        id: batProc
        command: ["sh", "-c",
            "printf '%s|%s' \"$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null)\" " +
            "\"$(cat /sys/class/power_supply/BAT0/status 2>/dev/null)\""]
        stdout: StdioCollector {
            onStreamFinished: {
                var p = this.text.trim().split("|");
                if (p[0] === "") { root.hasBattery = false; return; }
                root.hasBattery = true;
                root.battery = parseInt(p[0]) || 0;
                root.charging = (p[1] === "Charging" || p[1] === "Full");
            }
        }
    }

    Process {
        id: netProc
        command: ["sh", "-c",
            "w=$(nmcli -t -f ACTIVE,SSID,SIGNAL dev wifi 2>/dev/null | awk -F: '$1==\"yes\"{print $2\"~\"$3; exit}'); " +
            "s=$(nmcli -t -f STATE g 2>/dev/null); printf '%s;%s' \"$s\" \"$w\""]
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = this.text.trim().split(";");
                root.connected = (parts[0] === "connected" || parts[0] === "connected (site only)");
                var w = parts.length > 1 ? parts[1] : "";
                if (w && w.indexOf("~") >= 0) {
                    var wp = w.split("~");
                    root.wifi = true; root.ssid = wp[0]; root.signal = parseInt(wp[1]) || 0;
                } else { root.wifi = false; root.ssid = ""; root.signal = 0; }
            }
        }
    }

    Process {
        id: brightProc
        command: ["sh", "-c", "brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d '%'"]
        stdout: StdioCollector {
            onStreamFinished: { var v = parseInt(this.text.trim()); if (!isNaN(v)) root.brightness = v; }
        }
    }

    Process {
        id: btProc
        command: ["sh", "-c", "timeout 2 bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo 1 || echo 0"]
        stdout: StdioCollector { onStreamFinished: root.btPowered = (this.text.trim() === "1") }
    }

    Process {
        id: dndProc
        command: ["sh", "-c", "swaync-client -D 2>/dev/null"]
        stdout: StdioCollector { onStreamFinished: root.dnd = (this.text.trim() === "true") }
    }
}
