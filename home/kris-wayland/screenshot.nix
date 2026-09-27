{ pkgs, ... }:
let
  # driftshot: driftwm-native screenshots. Capture is done by the running
  # compositor (`driftwm msg screenshot`), which is canvas-accurate and knows
  # the focused window, so no output-coordinate math is needed. Helper tools
  # are referenced by absolute store path; `driftwm` comes from the running
  # system so the msg protocol always matches the live compositor.
  driftshot = pkgs.writeShellScriptBin "driftshot" ''
    set -euo pipefail

    slurp="${pkgs.slurp}/bin/slurp"
    satty="${pkgs.satty}/bin/satty"
    wlcopy="${pkgs.wl-clipboard}/bin/wl-copy"
    notify="${pkgs.libnotify}/bin/notify-send"

    mode="''${1:-region}"
    dir="''${SCREENSHOT_DIR:-$HOME/Pictures/Screenshots}"
    mkdir -p "$dir"
    file="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"

    finish() {
      "$wlcopy" --type image/png < "$file"
      "$notify" -a driftshot -i "$file" "$1" "$file" || true
    }

    case "$mode" in
      screen|full|output)
        driftwm msg screenshot -o "$file"
        finish "Screenshot saved"
        ;;
      window)
        driftwm msg screenshot window -o "$file"
        finish "Window captured"
        ;;
      canvas|all)
        driftwm msg screenshot all -o "$file"
        finish "Canvas captured"
        ;;
      region|area)
        # slurp may be cancelled (Esc) -> exit quietly, no file written
        geom="$("$slurp")" || exit 0
        driftwm msg screenshot region --from-screen "$geom" -o - \
          | "$satty" --filename - --output-filename "$file" \
              --early-exit --copy-command "$wlcopy"
        ;;
      *)
        echo "usage: driftshot [region|screen|window|canvas]" >&2
        exit 2
        ;;
    esac
  '';
in
{
  home.packages = [ driftshot pkgs.satty pkgs.libnotify ];
}
