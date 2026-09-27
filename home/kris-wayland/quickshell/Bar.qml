import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

PanelWindow {
    id: bar
    anchors { top: true; left: true; right: true }
    implicitHeight: Theme.barHeight
    color: "transparent"
    WlrLayershell.namespace: "qs-bar"
    WlrLayershell.layer: WlrLayer.Top


    Rectangle {
        anchors.fill: parent
        color: Theme.barGlass
    }
    Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 1
        color: Theme.hairline
    }


    readonly property var active: ToplevelManager.activeToplevel
    function prettyApp(t) {
        if (!t) return "Finder";
        var id = (t.appId && t.appId.length) ? t.appId : (t.title || "");
        if (!id.length) return "Finder";
        var seg = id.split(".").pop().split(" ")[0];
        return seg.charAt(0).toUpperCase() + seg.slice(1);
    }


    RowLayout {
        anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
        spacing: 16

        Text {
            text: "\uf179" //larp logo
            font.family: Theme.iconFont
            font.pixelSize: 15
            color: Theme.white
            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch("exec wofi --show drun")
            }
        }

        Text {
            text: bar.prettyApp(bar.active)
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            font.bold: true
            color: Theme.text
        }
    }

    RowLayout {
        id: right
        anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
        spacing: 4


        Repeater {
            model: SystemTray.items
            delegate: MouseArea {
                required property var modelData
                implicitWidth: 22; implicitHeight: 22
                Layout.alignment: Qt.AlignVCenter
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: (m) => {
                    if (m.button === Qt.LeftButton) modelData.activate();
                    else modelData.secondaryActivate();
                }
                IconImage {
                    anchors.centerIn: parent
                    implicitSize: 16
                    source: modelData.icon
                }
            }
        }

        BarChip {
            text: Sys.wifi ? "\uf1eb" : (Sys.connected ? "\uf0e8" : "\uf1eb")
            dim: !Sys.connected
            tooltip: Sys.wifi ? (Sys.ssid + "  " + Sys.signal + "%")
                              : (Sys.connected ? "Connected" : "Offline")
            onClicked: UI.toggleCC()
        }

        BarChip {
            visible: Sys.hasBattery
            text: batteryGlyph() + "  " + Sys.battery + "%"
            accent: Sys.charging
            tooltip: Sys.charging ? "Charging" : "On battery"
            function batteryGlyph() {
                if (Sys.charging) return "\uf0e7";
                var b = Sys.battery;
                if (b >= 88) return "\uf240";
                if (b >= 63) return "\uf241";
                if (b >= 38) return "\uf242";
                if (b >= 13) return "\uf243";
                return "\uf244";
            }
        }

        BarChip {
            id: clock
            property string now: ""
            text: now
            font.bold: true
            Timer {
                interval: 1000; running: true; repeat: true; triggeredOnStart: true
                onTriggered: clock.now = Qt.formatDateTime(new Date(), "ddd d MMM  H:mm")
            }
        }

        BarChip {
            text: "\uf1de"
            active: UI.ccOpen
            onClicked: UI.toggleCC()
        }
    }

    component BarChip: Item {
        id: chip
        property string text: ""
        property string tooltip: ""
        property bool accent: false
        property bool dim: false
        property bool active: false
        property alias font: label.font
        signal clicked()

        Layout.alignment: Qt.AlignVCenter
        implicitWidth: label.implicitWidth + 16
        implicitHeight: 20

        Rectangle {
            anchors.fill: parent
            radius: 7
            color: (chip.active || hover.hovered) ? Theme.hover : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.durFast } }
        }
        Text {
            id: label
            anchors.centerIn: parent
            text: chip.text
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            color: chip.dim ? Theme.danger : (chip.accent ? Theme.accent : Theme.text)
        }
        HoverHandler { id: hover }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: chip.clicked()
        }
        ToolTip.visible: chip.tooltip.length > 0 && hover.hovered
        ToolTip.text: chip.tooltip
        ToolTip.delay: 500
    }
}
