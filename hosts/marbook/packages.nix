{ pkgs, ... }: {
  nixpkgs.overlays = [
    (final: prev: {
      amneziawg-tools = prev.amneziawg-tools.overrideAttrs (_: {
        version = "1.0.20260223";
        src = prev.fetchFromGitHub {
          owner = "amnezia-vpn";
          repo = "amneziawg-tools";
          rev = "5d6179a6d0842e98dfb349c28cf1bd8e4b9d1079";
          hash = "sha256-pHmuxlrbTqjwRrB7BShdC4ENw3iVQRRLH+Z2w8x+KeE=";
        };
      });
    })
  ];

  environment.systemPackages = with pkgs; [
    android-tools
    amneziawg-tools
    amneziawg-go
    duti
    ghostty-bin
    gnupg
    keepassxc
    nodejs
    qbittorrent-enhanced
    obsidian
    syncthing-macos
    utm
    vlc-bin
    xld
    zed-editor
  ];

  homebrew = {
    enable = true;
    brews = [
      "audacious"
      "ghidra"
      "ocp"
      "omlx"
      "openssh"
      "ykman"
      "libfido2"
    ];
    casks = [
      "winbox"
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
