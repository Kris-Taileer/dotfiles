import subprocess

from libqtile import bar, extension, hook, layout, qtile, widget
from libqtile.config import Click, Drag, Group, Key, KeyChord, Match, Screen
from libqtile.lazy import lazy
from libqtile.utils import guess_terminal

mod = "mod4"
terminal = guess_terminal()

myTerm = "alacritty"

keys = [
    Key([mod], "r", lazy.spawn("rofi -show run")),
    Key([mod], "h", lazy.layout.left(), desc="Move focus to left"),
    Key([mod], "l", lazy.layout.right(), desc="Move focus to right"),
    Key([mod], "j", lazy.layout.down(), desc="Move focus down"),
    Key([mod], "k", lazy.layout.up(), desc="Move focus up"),
    Key([mod], "space", lazy.layout.next(), desc="Move window focus to other window"),
    Key(
        [mod, "shift"], "h", lazy.layout.shuffle_left(), desc="Move window to the left"
    ),
    Key(
        [mod, "shift"],
        "l",
        lazy.layout.shuffle_right(),
        desc="Move window to the right",
    ),
    Key([mod, "shift"], "j", lazy.layout.shuffle_down(), desc="Move window down"),
    Key([mod, "shift"], "k", lazy.layout.shuffle_up(), desc="Move window up"),
    Key([mod, "control"], "h", lazy.layout.grow_left(), desc="Grow window to the left"),
    Key(
        [mod, "control"], "l", lazy.layout.grow_right(), desc="Grow window to the right"
    ),
    Key([mod, "control"], "j", lazy.layout.grow_down(), desc="Grow window down"),
    Key([mod, "control"], "k", lazy.layout.grow_up(), desc="Grow window up"),
    Key([mod], "n", lazy.layout.normalize(), desc="Reset all window sizes"),
    Key(
        [mod, "shift"],
        "Return",
        lazy.layout.toggle_split(),
        desc="Toggle between split and unsplit sides of stack",
    ),
    Key([mod], "Return", lazy.spawn(terminal), desc="Launch terminal"),
    Key([mod], "Tab", lazy.next_layout(), desc="Toggle between layouts"),
    Key([mod], "q", lazy.window.kill(), desc="Kill focused window"),
    Key(
        [mod],
        "f",
        lazy.window.toggle_fullscreen(),
        desc="Toggle fullscreen on the focused window",
    ),
    Key(
        [mod],
        "t",
        lazy.window.toggle_floating(),
        desc="Toggle floating on the focused window",
    ),
    Key([mod, "control"], "r", lazy.restart(), desc="Restart Qtile"),
    Key([mod, "control"], "q", lazy.shutdown(), desc="Shutdown Qtile"),
    Key([mod], "d", lazy.spawn("rofi -show drun -show-icons"), desc="Run Launcher"),
    Key(
        [mod],
        "s",
        lazy.spawn('sh -c "grim -g \\"$(slurp)\\" - | wl-copy"'),
        desc="Screenshot",
    ),
    Key(
        [],
        "XF86AudioRaiseVolume",
        lazy.spawn("pactl set-sink-volume @DEFAULT_SINK@ +5%"),
    ),
    Key(
        [],
        "XF86AudioLowerVolume",
        lazy.spawn("pactl set-sink-volume @DEFAULT_SINK@ -5%"),
    ),
    Key([], "XF86AudioMute", lazy.spawn("pactl set-sink-mute @DEFAULT_SINK@ toggle")),
]

for vt in range(1, 8):
    keys.append(
        Key(
            ["control", "mod1"],
            f"f{vt}",
            lazy.core.change_vt(vt).when(func=lambda: qtile.core.name == "wayland"),
            desc=f"Switch to VT{vt}",
        )
    )

groups = [Group(i) for i in "123456789"]

for i in groups:
    keys.extend(
        [
            Key(
                [mod],
                i.name,
                lazy.group[i.name].toscreen(),
                desc=f"Switch to group {i.name}",
            ),
            Key(
                [mod, "shift"],
                i.name,
                lazy.window.togroup(i.name),
                desc="move focused window to group {}".format(i.name),
            ),
        ]
    )

colors = [
    ["#0d0e1a", "#0d0e1a"],
    ["#f5f3ff", "#f5f3ff"],
    ["#262442", "#262442"],
    ["#ff2e6d", "#ff2e6d"],
    ["#39ff9e", "#39ff9e"],
    ["#ffe14d", "#ffe14d"],
    ["#4dd9ec", "#4dd9ec"],
    ["#b15cff", "#b15cff"],
    ["#5ef1ff", "#5ef1ff"],
    ["#6e6a8c", "#6e6a8c"],
]

layout_theme = {
    "border_width": 1,
    "margin": 1,
    "border_focus": colors[7],
    "border_normal": colors[0],
}

layouts = [
    layout.Columns(**layout_theme),
    layout.Max(),
    layout.MonadTall(**layout_theme),
]

widget_defaults = dict(
    font="JetBrainsMono Nerd Font Propo Bold",
    fontsize=16,
    padding=0,
    background=colors[0],
)

extension_defaults = widget_defaults.copy()

sep = widget.Sep(linewidth=1, padding=8, foreground=colors[9])

screens = [
    Screen(
        top=bar.Bar(
            widgets=[
                widget.Spacer(length=4),
                widget.GroupBox(
                    fontsize=18,
                    margin_y=5,
                    margin_x=5,
                    padding_y=0,
                    padding_x=2,
                    borderwidth=3,
                    active=colors[8],
                    inactive=colors[9],
                    rounded=False,
                    highlight_color=colors[0],
                    highlight_method="line",
                    this_current_screen_border=colors[7],
                    this_screen_border=colors[6],
                    other_current_screen_border=colors[7],
                    other_screen_border=colors[6],
                ),
                widget.TextBox(
                    text="|",
                    font="JetBrainsMono Nerd Font Propo Bold",
                    foreground=colors[9],
                    padding=2,
                    fontsize=14,
                ),
                widget.Image(
                    filename="~/.config/qtile/icons/tonybtw.png",
                    scale=False,
                    mouse_callbacks={
                        "Button1": lambda: qtile.cmd_spawn("qtilekeys-yad")
                    },
                ),
                widget.Prompt(
                    font="JetBrainsMono Nerd Font Propo Bold",
                    fontsize=18,
                    foreground=colors[1],
                ),
                widget.TextBox(
                    text="|",
                    font="JetBrainsMono Nerd Font Propo Bold",
                    foreground=colors[9],
                    padding=2,
                    fontsize=14,
                ),
                widget.CurrentLayout(foreground=colors[1], padding=5),
                widget.TextBox(
                    text="|",
                    font="JetBrainsMono Nerd Font Propo Bold",
                    foreground=colors[9],
                    padding=2,
                    fontsize=14,
                ),
                widget.WindowName(
                    foreground=colors[7],
                    padding=8,
                    max_chars=25,
                ),
                widget.Spacer(),
                widget.GenPollText(
                    update_interval=300,
                    func=lambda: subprocess.check_output(
                        "uname -r", shell=True, text=True
                    ).strip(),
                    foreground=colors[4],
                    padding=8,
                    fmt="{}",
                ),
                sep,
                widget.CPU(
                    foreground=colors[6],
                    padding=8,
                    mouse_callbacks={
                        "Button1": lambda: qtile.cmd_spawn(myTerm + " -e btop")
                    },
                    format="CPU: {load_percent}%",
                ),
                sep,
                widget.Memory(
                    foreground=colors[8],
                    padding=8,
                    mouse_callbacks={
                        "Button1": lambda: qtile.cmd_spawn(myTerm + " -e btop")
                    },
                    format="Mem: {MemUsed:.0f}{mm}",
                ),
                sep,
                widget.DF(
                    update_interval=60,
                    foreground=colors[5],
                    padding=8,
                    mouse_callbacks={"Button1": lambda: qtile.cmd_spawn("notify-disk")},
                    partition="/",
                    format="{uf}{m} free",
                    fmt="Disk: {}",
                    visible_on_warn=False,
                ),
                sep,
                widget.Battery(
                    foreground=colors[7],
                    padding=8,
                    update_interval=5,
                    format="{percent:2.0%} {char} {hour:d}:{min:02d}",
                    fmt="Bat: {}",
                    charge_char="",
                    discharge_char="",
                    full_char="✔",
                    unknown_char="?",
                    empty_char="!",
                    mouse_callbacks={
                        "Button1": lambda: qtile.cmd_spawn(
                            myTerm + " -e upower -i $(upower -e | grep BAT)"
                        ),
                    },
                ),
                sep,
                widget.Volume(
                    foreground=colors[6],
                    padding=8,
                    fmt="Vol: {}",
                ),
                sep,
                widget.Clock(
                    foreground=colors[8],
                    padding=8,
                    mouse_callbacks={"Button1": lambda: qtile.cmd_spawn("notify-date")},
                    format="%a, %b %d - %H:%M",
                ),
                widget.Systray(padding=6),
                widget.Spacer(length=8),
            ],
            margin=[0, 0, 0, 0],
            size=35,
        ),
    ),
]

mouse = [
    Drag(
        [mod],
        "Button1",
        lazy.window.set_position_floating(),
        start=lazy.window.get_position(),
    ),
    Drag(
        [mod], "Button3", lazy.window.set_size_floating(), start=lazy.window.get_size()
    ),
    Click([mod], "Button2", lazy.window.bring_to_front()),
]

dgroups_key_binder = None
dgroups_app_rules = []  # type: list
follow_mouse_focus = True
bring_front_click = False
floats_kept_above = True
cursor_warp = False
floating_layout = layout.Floating(
    float_rules=[
        *layout.Floating.default_float_rules,
        Match(wm_class="confirmreset"),
        Match(wm_class="makebranch"),
        Match(wm_class="maketag"),
        Match(wm_class="ssh-askpass"),
        Match(title="branchdialog"),
        Match(title="pinentry"),
    ]
)
auto_fullscreen = True
focus_on_window_activation = "smart"
reconfigure_screens = True
auto_minimize = True

from libqtile.backend.wayland import InputConfig

wl_input_rules = {
    "*": InputConfig(kb_layout="us,ru", kb_options="grp:alt_shift_toggle"),
}
wl_xcursor_theme = None
wl_xcursor_size = 24


@hook.subscribe.startup_once
def autostart():
    subprocess.Popen(["wlr-randr", "--output", "eDP-1", "--scale", "1.5"])
    subprocess.Popen(["waypaper", "--restore"])


wmname = "LG3D"
