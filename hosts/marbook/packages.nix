{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    anki
    keepassxc
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
    casks = [ "vesktop" ];
  };
}
