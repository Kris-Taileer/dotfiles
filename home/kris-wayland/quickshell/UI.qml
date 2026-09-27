pragma Singleton

import Quickshell
import QtQuick

Singleton {
    property bool ccOpen: false
    function toggleCC() { ccOpen = !ccOpen; }
    function closeCC()  { ccOpen = false; }
}
