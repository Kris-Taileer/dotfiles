{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    android-tools
    duti
    ghostty-bin
    keepassxc
    nodejs
    qbittorrent-enhanced
    obsidian
    syncthing-macos
    utm
    vlc-bin
    thunderbird
    xld
    zed-editor
  ];

  homebrew = {
    enable = true;
    brews = [
      "audacious"
      "ocp"
      "omlx"
    ];
    casks = [
      "vesktop"
      "anki"
      "prismlauncher"
      "milkytracker"
    ];

    taps = [
      {
        name = "jundot/omlx";
        clone_target = "https://github.com/jundot/omlx";
      }
    ];
  };
}
