import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick

PanelWindow {
    id: dock
    anchors { bottom: true }
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.namespace: "qs-dock"
    WlrLayershell.layer: WlrLayer.Top

    implicitWidth: bg.width + 80
    implicitHeight: 232

    readonly property int base: 106
    readonly property real peak: 1.4
    readonly property real sigma: 100
    property real mx: -10000
    property bool hovering: false

    readonly property bool revealed: revealHover.hovered || hovering
    readonly property real hideOffset: bg.height + 16

    readonly property var pinned: [
        { key: "dolphin",  name: "Finder",   icon: "org.kde.dolphin",        exec: "dolphin"  },
        { key: "zen",      name: "Zen",      icon: "zen-browser",            exec: "zen-beta" },
        { key: "obsidian", name: "Obsidian", icon: "obsidian",               exec: "obsidian" },
        { key: "ghostty",  name: "Ghostty",  icon: "com.mitchellh.ghostty",  exec: "ghostty"  },
        { key: "gwenview", name: "Gallery",  icon: "gwenview",               exec: "gwenview" },
        { key: "zed",      name: "Zed",      icon: "zed",                    exec: "zeditor"  },
        { key: "ida",      name: "IDA Pro",  iconSrc: "file:///home/kris/ida-pro-9.3/appico.png",
                           exec: "/home/kris/ida-pro-9.3/ida-launch.sh" },
    ]
    function isPinned(appId) {
        if (!appId) return false;
        var a = appId.toLowerCase();
        for (var i = 0; i < pinned.length; i++)
            if (a.indexOf(pinned[i].key) >= 0) return true;
        return false;
    }
    function runningFor(key) {
        var out = [];
        var tl = ToplevelManager.toplevels.values;
        for (var i = 0; i < tl.length; i++)
            if (tl[i].appId && tl[i].appId.toLowerCase().indexOf(key) >= 0) out.push(tl[i]);
        return out;
    }
    readonly property var extras: {
        var out = [];
        var tl = ToplevelManager.toplevels.values;
        for (var i = 0; i < tl.length; i++)
            if (tl[i].appId && !isPinned(tl[i].appId)) out.push(tl[i]);
        return out;
    }

    Item {
        id: revealArea
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width:  dock.revealed ? bg.width + 24 : 640
        height: dock.revealed ? dock.height : 30
        HoverHandler { id: revealHover }
    }
    mask: Region { item: revealArea }

    Rectangle {
        id: peek
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 5
        anchors.horizontalCenter: parent.horizontalCenter
        width: 70; height: 17; radius: 8
        color: Theme.bgGlass
        border.width: 1; border.color: Theme.hairline
        opacity: dock.revealed ? 0 : 1
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Theme.dur; easing.type: Theme.easeOut } }
        Row {
            anchors.centerIn: parent
            spacing: 6
            Repeater {
                model: 3
                Rectangle { width: 5; height: 5; radius: 2.5; color: Theme.subtext }
            }
        }
    }

    Rectangle {
        id: bg
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 8
        width: row.implicitWidth + 24
        height: dock.base + 20
        radius: Theme.radiusLg
        color: Theme.bgGlass
        border.width: 1
        border.color: Theme.hairline

        transform: Translate {
            y: dock.revealed ? 0 : dock.hideOffset
            Behavior on y { NumberAnimation { duration: Theme.dur; easing.type: Theme.easeOut } }
        }
        opacity: dock.revealed ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.durFast } }

        Row {
            id: row
            anchors.centerIn: parent
            height: dock.base
            spacing: 14

            Repeater {
                model: dock.pinned
                DockItem {
                    required property var modelData
                    icon: modelData.iconSrc ? modelData.iconSrc
                                            : Quickshell.iconPath(modelData.icon, "application-x-executable")
                    label: modelData.name
                    running: dock.runningFor(modelData.key).length > 0
                    onActivate: {
                        var r = dock.runningFor(modelData.key);
                        if (r.length > 0) r[0].activate();
                        else Hyprland.dispatch("exec " + modelData.exec);
                    }
                }
            }

            DockDivider { visible: dock.extras.length > 0 }
            Repeater {
                model: dock.extras
                DockItem {
                    required property var modelData
                    icon: Quickshell.iconPath(modelData.appId, "application-x-executable")
                    label: modelData.title || modelData.appId
                    running: true
                    onActivate: modelData.activate()
                }
            }
        }

        HoverHandler {
            id: hh
            onPointChanged: dock.mx = hh.point.position.x + bg.x
        }
        Binding { target: dock; property: "hovering"; value: hh.hovered }
    }

    component DockDivider: Rectangle {
        width: 1; height: dock.base - 16
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        color: Theme.hairline
    }

    component DockItem: Item {
        id: it
        property string icon: ""
        property string label: ""
        property bool running: false
        signal activate()

        width: dock.base
        height: dock.base
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined

        readonly property real centerX: x + width / 2 + (parent ? parent.x : 0) + bg.x
        readonly property real dist: dock.revealed ? Math.abs(centerX - dock.mx) : 100000
        readonly property real mag: Math.exp(-(dist * dist) / (2 * dock.sigma * dock.sigma))
        property real scl: 1 + (dock.peak - 1) * mag
        Behavior on scl { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }

        Item {
            id: iconWrap
            width: dock.base; height: dock.base
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            scale: it.scl
            transformOrigin: Item.Bottom
            IconImage {
                anchors.centerIn: parent
                implicitSize: dock.base - 14
                source: it.icon
                visible: it.icon.length > 0
            }
        }

        Rectangle {
            width: 5; height: 5; radius: 2.5
            color: Theme.text
            opacity: it.running ? 0.9 : 0
            anchors.bottom: parent.bottom
            anchors.bottomMargin: -7
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Rectangle {
            visible: it.dist < dock.base * 0.4
            anchors.bottom: iconWrap.top
            anchors.bottomMargin: 12 + (it.scl - 1) * dock.base
            anchors.horizontalCenter: parent.horizontalCenter
            width: lbl.implicitWidth + 18
            height: lbl.implicitHeight + 10
            radius: 8
            color: Theme.bgGlass
            border.width: 1; border.color: Theme.hairline
            Text {
                id: lbl
                anchors.centerIn: parent
                text: it.label
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                color: Theme.text
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: it.activate()
        }
    }
}
