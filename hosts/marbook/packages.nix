{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    anki
    android-tools
    duti
    ghostty-bin
    keepassxc
    nodejs
    qbittorrent-enhanced
    jetbrains.idea
    obsidian
    syncthing-macos
    thunderbird
    zed-editor
  ];

  homebrew = {
    enable = true;
    brews = [
      "audacious"
      "ocp"
    ];
    casks = [
      "vesktop"
    ];
  };
}
