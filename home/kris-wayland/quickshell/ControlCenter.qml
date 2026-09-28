import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import QtQuick

PanelWindow {
    id: cc
    visible: UI.ccOpen
    anchors { top: true; left: true; right: true; bottom: true }
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.namespace: "qs-control-center"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    onVisibleChanged: if (visible) { Sys.refreshAll(); openAnim.restart(); }

    PwObjectTracker { objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : [] }
    readonly property var audio: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null

    readonly property var players: Mpris.players ? Mpris.players.values : []
    readonly property var player: {
        if (!players || players.length === 0) return null;
        for (var i = 0; i < players.length; i++) if (players[i].isPlaying) return players[i];
        return players[0];
    }

    MouseArea { anchors.fill: parent; onClicked: UI.closeCC() }

    Rectangle {
        id: card
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: Theme.barHeight + 6
        anchors.rightMargin: 8
        width: 340
        height: col.implicitHeight + 24
        radius: Theme.radiusLg
        color: Theme.bgGlass
        border.width: 1
        border.color: Theme.hairline
        transformOrigin: Item.TopRight

        MouseArea { anchors.fill: parent }

        ParallelAnimation {
            id: openAnim
            NumberAnimation { target: card; property: "opacity"; from: 0; to: 1; duration: Theme.dur; easing.type: Theme.easeOut }
            NumberAnimation { target: card; property: "scale";   from: 0.94; to: 1; duration: Theme.dur; easing.type: Theme.easeOut }
        }

        Column {
            id: col
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
            spacing: 10

            Rectangle {
                width: parent.width
                height: conn.implicitHeight + 16
                radius: Theme.radius
                color: Theme.surface
                Column {
                    id: conn
                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 10 }
                    spacing: 4
                    ConnRow {
                        glyph: Sys.wifi ? "\uf1eb" : "\uf1eb"
                        title: "Wi-Fi"
                        subtitle: Sys.wifi ? Sys.ssid : (Sys.connected ? "Wired" : "Off")
                        on: Sys.wifi || Sys.connected
                        onToggle: Sys.toggleWifi()
                    }
                    Rectangle { width: parent.width; height: 1; color: Theme.hairline }
                    ConnRow {
                        glyph: "\uf293"
                        title: "Bluetooth"
                        subtitle: Sys.btPowered ? "On" : "Off"
                        on: Sys.btPowered
                        onToggle: Sys.toggleBt()
                    }
                }
            }


            Row {
                width: parent.width
                spacing: 10
                CCTile {
                    glyph: Sys.dnd ? "\uf186" : "\uf0f3"
                    label: "Do Not Disturb"
                    on: Sys.dnd
                    onTap: Sys.toggleDnd()
                }
                CCTile {
                    glyph: "\uf023"
                    label: "Lock Screen"
                    on: false
                    onTap: { UI.closeCC(); Hyprland.dispatch("exec applelock"); }
                }
            }

            CCSlider {
                width: parent.width
                glyph: "\uf185"
                value: Sys.brightness / 100
                onMoved: (v) => Sys.setBrightness(Math.max(5, v * 100))
            }

            CCSlider {
                width: parent.width
                glyph: cc.audio && cc.audio.muted ? "\uf6a9" : "\uf028"
                value: cc.audio ? cc.audio.volume : 0
                onMoved: (v) => { if (cc.audio) cc.audio.volume = v; }
                onIconTap: { if (cc.audio) cc.audio.muted = !cc.audio.muted; }
            }

            Rectangle {
                width: parent.width
                height: 62
                radius: Theme.radius
                color: Theme.surface
                visible: cc.player !== null

                Rectangle {
                    id: ccArt
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 8 }
                    width: 46; height: 46; radius: 8; clip: true; color: Theme.bg
                    Image {
                        anchors.fill: parent
                        source: cc.player && cc.player.trackArtUrl ? cc.player.trackArtUrl : ""
                        fillMode: Image.PreserveAspectCrop
                        visible: status === Image.Ready
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: !(cc.player && cc.player.trackArtUrl)
                        text: "\uf001"; font.family: Theme.iconFont; font.pixelSize: 16; color: Theme.subtext
                    }
                }
                Column {
                    anchors { left: ccArt.right; right: ccControls.left; verticalCenter: parent.verticalCenter; leftMargin: 10; rightMargin: 8 }
                    spacing: 1
                    Text {
                        width: parent.width; elide: Text.ElideRight
                        text: cc.player ? (cc.player.trackTitle || "Unknown") : ""
                        font.family: Theme.font; font.pixelSize: Theme.fontSize; font.bold: true; color: Theme.text
                    }
                    Text {
                        width: parent.width; elide: Text.ElideRight
                        text: cc.player ? (cc.player.trackArtist || "") : ""
                        font.family: Theme.font; font.pixelSize: Theme.fontSizeSm; color: Theme.subtext
                    }
                }
                Row {
                    id: ccControls
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: 12 }
                    spacing: 14
                    MediaBtn { glyph: "\uf048"; onTap: if (cc.player) cc.player.previous() }
                    MediaBtn { glyph: (cc.player && cc.player.isPlaying) ? "\uf04c" : "\uf04b"; big: true; onTap: if (cc.player) cc.player.togglePlaying() }
                    MediaBtn { glyph: "\uf051"; onTap: if (cc.player) cc.player.next() }
                }
            }
        }
    }

    component ConnRow: Item {
        property string glyph: ""
        property string title: ""
        property string subtitle: ""
        property bool on: false
        signal toggle()
        width: parent ? parent.width : 0
        implicitHeight: 40
        Rectangle {
            id: dot
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            width: 30; height: 30; radius: 15
            color: on ? Theme.accent : Theme.hover
            Behavior on color { ColorAnimation { duration: Theme.durFast } }
            Text { anchors.centerIn: parent; text: glyph; font.family: Theme.iconFont; font.pixelSize: 14; color: Theme.white }
        }
        Column {
            anchors { left: dot.right; verticalCenter: parent.verticalCenter; leftMargin: 10 }
            spacing: 0
            Text { text: title; font.family: Theme.font; font.pixelSize: Theme.fontSize; font.bold: true; color: Theme.text }
            Text { text: subtitle; font.family: Theme.font; font.pixelSize: Theme.fontSizeSm; color: Theme.subtext }
        }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: parent.toggle() }
    }

    component CCTile: Rectangle {
        property string glyph: ""
        property string label: ""
        property bool on: false
        signal tap()
        width: (340 - 24 - 10) / 2
        height: 64
        radius: Theme.radius
        color: on ? Theme.accent : Theme.surface
        Behavior on color { ColorAnimation { duration: Theme.durFast } }
        Column {
            anchors.centerIn: parent
            spacing: 4
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: glyph; font.family: Theme.iconFont; font.pixelSize: 18; color: Theme.text }
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: label; font.family: Theme.font; font.pixelSize: Theme.fontSizeSm; color: Theme.text }
        }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: parent.tap() }
    }

    component CCSlider: Item {
        property string glyph: ""
        property real value: 0
        signal moved(real v)
        signal iconTap()
        implicitHeight: 30
        Rectangle {
            id: strack
            anchors.fill: parent
            radius: height / 2
            color: Theme.surface
            Rectangle {
                id: sfill
                height: parent.height
                width: Math.max(parent.height, parent.width * Math.max(0, Math.min(1, value)))
                radius: parent.radius
                color: Theme.white
            }
            Text {
                anchors { left: parent.left; leftMargin: 9; verticalCenter: parent.verticalCenter }
                text: glyph; font.family: Theme.iconFont; font.pixelSize: 14
                color: Theme.bg
                MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: iconTap() }
            }
            MouseArea {
                anchors.fill: parent
                onPressed: (m) => moved(Math.max(0, Math.min(1, m.x / width)))
                onPositionChanged: (m) => { if (pressed) moved(Math.max(0, Math.min(1, m.x / width))); }
            }
        }
    }

    component MediaBtn: Text {
        property string glyph: ""
        property bool big: false
        signal tap()
        text: glyph
        font.family: Theme.iconFont
        font.pixelSize: big ? 16 : 12
        color: Theme.text
        MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: parent.tap() }
    }
}
