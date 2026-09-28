import Quickshell
import QtQuick

ShellRoot {
    Variants {
        model: Quickshell.screens

        delegate: Scope {
            required property var modelData

            Bar   { screen: modelData }
            Notch { screen: modelData }
            Dock  { screen: modelData }
        }
    }

    ControlCenter {}
}
