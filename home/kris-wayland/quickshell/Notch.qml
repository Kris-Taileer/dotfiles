import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import QtQuick

PanelWindow {
    id: w
    anchors { top: true }
    exclusiveZone: -1
    implicitWidth: 420
    implicitHeight: 100
    color: "transparent"
    WlrLayershell.namespace: "qs-notch"
    WlrLayershell.layer: WlrLayer.Overlay

    mask: Region { item: pill }

    PwObjectTracker { objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : [] }
    readonly property var audio: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
    readonly property real volume: audio ? audio.volume : 0
    readonly property bool muted: audio ? audio.muted : false

    readonly property var players: Mpris.players ? Mpris.players.values : []
    readonly property var player: {
        if (!players || players.length === 0) return null;
        for (var i = 0; i < players.length; i++)
            if (players[i].isPlaying) return players[i];
        return players[0];
    }
    readonly property bool hasMedia: player !== null

    property string mode: "rest"
    property bool ready: false

    readonly property bool showVolume: mode === "volume"
    readonly property bool showMedia:  !showVolume && hasMedia && (mode === "media" || hover.hovered)
    readonly property bool expanded:   showVolume || showMedia

    Component.onCompleted: readyTimer.start()
    Timer { id: readyTimer; interval: 1400; onTriggered: w.ready = true }
    Timer { id: collapse; interval: 1600; onTriggered: w.mode = "rest" }

    function peek(m) { if (!ready) return; mode = m; collapse.restart(); }

    Connections {
        target: w.audio
        function onVolumeChanged() { w.peek("volume"); }
        function onMutedChanged()  { w.peek("volume"); }
    }
    Connections {
        target: w.player
        ignoreUnknownSignals: true
        function onTrackTitleChanged() { if (w.player && w.player.isPlaying) w.peek("media"); }
    }

    Rectangle {
        id: pill
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        color: Theme.notch

        width:  w.showVolume ? 360 : (w.showMedia ? 400 : 220)
        height: w.expanded ? 92 : Theme.barHeight
        topLeftRadius: 0
        topRightRadius: 0
        bottomLeftRadius: w.expanded ? 24 : 18
        bottomRightRadius: w.expanded ? 24 : 18

        Behavior on width  { NumberAnimation { duration: Theme.dur; easing.type: Theme.easeOut } }
        Behavior on height { NumberAnimation { duration: Theme.dur; easing.type: Theme.easeOut } }
        Behavior on bottomLeftRadius  { NumberAnimation { duration: Theme.dur } }
        Behavior on bottomRightRadius { NumberAnimation { duration: Theme.dur } }

        HoverHandler { id: hover }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 22
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3
            opacity: (!w.expanded && w.hasMedia && w.player && w.player.isPlaying) ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.durFast } }
            Repeater {
                model: 3
                Rectangle {
                    width: 3; radius: 1.5
                    color: Theme.accent
                    anchors.verticalCenter: parent.verticalCenter
                    height: index === 1 ? 13 : (index === 0 ? 7 : 6)
                }
            }
        }

        Item {
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            opacity: w.showVolume ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.durFast } }

            Text {
                id: volIcon
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: w.muted ? "\uf6a9" : (w.volume > 0.5 ? "\uf028" : "\uf027")
                font.family: Theme.iconFont
                font.pixelSize: 20
                color: Theme.white
            }
            Rectangle {
                id: volTrack
                anchors.left: volIcon.right
                anchors.leftMargin: 16
                anchors.right: volPct.left
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                height: 6; radius: 3
                color: Theme.hover
                Rectangle {
                    height: parent.height; radius: 3
                    width: parent.width * Math.max(0, Math.min(1, w.muted ? 0 : w.volume))
                    color: Theme.white
                    Behavior on width { NumberAnimation { duration: Theme.durFast } }
                }
            }
            Text {
                id: volPct
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: Math.round((w.muted ? 0 : w.volume) * 100) + "%"
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                color: Theme.text
            }
        }

        Item {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 14
            opacity: w.showMedia ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Theme.durFast } }

            Rectangle {
                id: art
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 46; height: 46; radius: 10
                color: Theme.surface
                clip: true
                Image {
                    anchors.fill: parent
                    source: w.player && w.player.trackArtUrl ? w.player.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                }
                Text {
                    anchors.centerIn: parent
                    visible: !(w.player && w.player.trackArtUrl)
                    text: "\uf001"
                    font.family: Theme.iconFont
                    font.pixelSize: 18
                    color: Theme.subtext
                }
            }

            Column {
                anchors.left: art.right
                anchors.leftMargin: 12
                anchors.right: controls.left
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Text {
                    width: parent.width
                    text: w.player ? (w.player.trackTitle || "Unknown") : ""
                    elide: Text.ElideRight
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    font.bold: true
                    color: Theme.text
                }
                Text {
                    width: parent.width
                    text: w.player ? (w.player.trackArtist || "") : ""
                    elide: Text.ElideRight
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSizeSm
                    color: Theme.subtext
                }
            }

            Row {
                id: controls
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10
                NotchButton {
                    glyph: "\uf048"
                    enabled: w.player && w.player.canGoPrevious
                    onTap: if (w.player) w.player.previous()
                }
                NotchButton {
                    glyph: (w.player && w.player.isPlaying) ? "\uf04c" : "\uf04b"
                    big: true
                    onTap: if (w.player) w.player.togglePlaying()
                }
                NotchButton {
                    glyph: "\uf051"
                    enabled: w.player && w.player.canGoNext
                    onTap: if (w.player) w.player.next()
                }
            }
        }
    }

    component NotchButton: Text {
        property string glyph: ""
        property bool big: false
        signal tap()
        text: glyph
        font.family: Theme.iconFont
        font.pixelSize: big ? 18 : 13
        color: enabled ? Theme.white : Theme.subtext
        opacity: enabled ? 1 : 0.4
        MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.tap()
        }
    }
}
