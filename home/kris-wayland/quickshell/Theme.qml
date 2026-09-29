pragma Singleton

import Quickshell
import QtQuick

Singleton {

    readonly property color bg:        "#1e1e1e"
    readonly property color bgGlass:   "#e61c1c1e"
    readonly property color barGlass:  "#8c1e1e1e"
    readonly property color surface:   "#2c2c2e"
    readonly property color notch:     "#f2000000"
    readonly property color text:      "#ededed"
    readonly property color subtext:   "#a0a0a5"
    readonly property color accent:    "#0a84ff"
    readonly property color white:     "#ffffff"
    readonly property color hairline:  "#1affffff"
    readonly property color hover:     "#28ffffff"
    readonly property color danger:    "#ff5f57"

    readonly property color tlClose:   "#cfcfd2"
    readonly property color tlMin:     "#9a9a9e"
    readonly property color tlMax:     "#6a6a6e"

    readonly property int barHeight:   32
    readonly property int radius:      14
    readonly property int radiusLg:    20
    readonly property int radiusSm:    10
    readonly property int gap:         8

    readonly property string font:     "Monocraft"
    readonly property string iconFont: "JetBrainsMono Nerd Font"
    readonly property int fontSize:    13
    readonly property int fontSizeSm:  11

    readonly property int durFast:     140
    readonly property int dur:         220
    readonly property int durSlow:     380
    readonly property var easeOut:     Easing.OutExpo
    readonly property var easeInOut:   Easing.InOutQuart
}
