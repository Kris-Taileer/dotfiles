
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import Quickshell.Io
import QtQuick

ShellRoot {
    id: root

    readonly property string wallpaper: "file:///home/kris/.config/hypr/wallpaper.png"
    property bool revealed: false
    property string pw: ""
    property bool busy: false
    property bool failed: false

    function beginUnlock() { root.revealed = false; releaseTimer.start(); }
    Timer { id: releaseTimer; interval: 620; onTriggered: lock.locked = false }

    Component.onCompleted: dropTimer.start()
    Timer { id: dropTimer; interval: 70; onTriggered: root.revealed = true }

    IpcHandler { target: "lock"; function unlock(): void { root.beginUnlock(); } }

    PamContext {
        id: pam
        config: "hyprlock"
        onCompleted: (res) => {
            root.busy = false;
            if (res === PamResult.Success) root.beginUnlock();
            else { root.failed = true; root.pw = ""; }
        }
    }
    function submit() {
        if (root.busy || root.pw.length === 0) return;
        root.failed = false; root.busy = true;
        pam.start(root.pw);
    }

    WlSessionLock {
        id: lock
        locked: true
        onLockedChanged: if (!locked) Qt.quit()

        surface: WlSessionLockSurface {
            id: surf
            color: "black"

            Image {
                anchors.fill: parent
                source: root.wallpaper
                fillMode: Image.PreserveAspectCrop
                cache: true
            }

            Item {
                id: curtain
                width: parent.width
                height: parent.height
                y: root.revealed ? 0 : -height
                Behavior on y { NumberAnimation { duration: 820; easing.type: Easing.OutCubic } }

                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#d9101014" }
                        GradientStop { position: 0.45; color: "#8c101014" }
                        GradientStop { position: 1.0; color: "#66101014" }
                    }
                }

                Text {
                    id: dateT
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: parent.height * 0.22
                    color: "#e8ededed"
                    font.family: "Monocraft"
                    font.pixelSize: 22
                    property string v: ""
                    text: v
                }

                Text {
                    id: timeT
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: parent.height * 0.22 + 40
                    color: "#ffffff"
                    font.family: "Monocraft"
                    font.pixelSize: 120
                    property string v: ""
                    text: v
                }
                Timer {
                    interval: 1000; running: true; repeat: true; triggeredOnStart: true
                    onTriggered: {
                        var d = new Date();
                        timeT.v = Qt.formatDateTime(d, "HH:mm");
                        dateT.v = Qt.formatDateTime(d, "dddd, d MMMM");
                    }
                }

                Item {
                    id: pwArea
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: parent.height * 0.72
                    width: 320
                    height: 54

                    Rectangle {
                        anchors.fill: parent
                        radius: 27
                        color: "#26ffffff"
                        border.width: 1
                        border.color: root.failed ? "#ff5f57" : "#33ffffff"
                        Behavior on border.color { ColorAnimation { duration: 160 } }
                    }

                    Row {
                        anchors.centerIn: parent
                        spacing: 10
                        visible: root.pw.length > 0
                        Repeater {
                            model: Math.min(root.pw.length, 12)
                            Rectangle { width: 9; height: 9; radius: 4.5; color: "#ffffff" }
                        }
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: root.pw.length === 0
                        text: root.busy ? "Authenticating…" : (root.failed ? "Try again" : "Enter Password")
                        color: "#a8ededed"
                        font.family: "Monocraft"
                        font.pixelSize: 14
                    }

                    SequentialAnimation on x {
                        id: shake
                        running: false
                        loops: 2
                        NumberAnimation { to: pwArea.x - 10; duration: 45 }
                        NumberAnimation { to: pwArea.x + 10; duration: 45 }
                        NumberAnimation { to: pwArea.x; duration: 45 }
                    }
                }

                TextInput {
                    id: field
                    visible: false
                    focus: true
                    enabled: !root.busy
                    onTextChanged: root.pw = text
                    onAccepted: root.submit()
                    Component.onCompleted: forceActiveFocus()
                }

                Connections {
                    target: root
                    function onPwChanged() { if (root.pw === "") field.text = ""; }
                    function onFailedChanged() { if (root.failed) { shake.start(); field.forceActiveFocus(); } }
                }
            }
        }
    }
}
