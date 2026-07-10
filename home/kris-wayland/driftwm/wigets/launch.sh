#!/usr/bin/env bash
# Launch all driftwm dashboard widgets as foot terminals.
DIR="$(cd "$(dirname "$0")" && pwd)"
CFG="$HOME/.config/driftwm/foot-widget.ini"

launch() {
    local name="$1" cols="$2" lines="$3" script="$4"
    foot --config="$CFG" \
        --app-id="drift-${name}" \
        --window-size-chars="${cols}x${lines}" \
        -- python3 "$DIR/${script}" &
}

launch clock       34 6  clock_widget.py
launch stats       34 11 stats_widget.py
launch canvas      26 4  canvas_widget.py
launch layout      6  4  layout_widget.py
launch calendar    22 11 calendar_widget.py
launch weather     22 6  weather_widget.py
launch notif       21 4  notif_widget.py

foot --config="$CFG" \
    --app-id="drift-power" \
    --window-size-chars="3x1" \
    -- python3 "$DIR/power_widget.py" &

wait
