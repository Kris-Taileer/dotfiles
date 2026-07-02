{ config, lib, pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 3;

  networking.hostName = "nixos-btw";
  networking.networkmanager.enable = true;
  networking.networkmanager.dns = "systemd-resolved";
  networking.firewall.enable = true;

  time.timeZone = "Europe/Moscow";
  hardware.graphics.enable = true;
  hardware.graphics.extraPackages = with pkgs; [ intel-media-driver vpl-gpu-rt ];
  services.xserver = {
    enable = true;
    autoRepeatDelay = 200;
    autoRepeatInterval = 35;
    windowManager.qtile = {
      enable = true;
      extraPackages = python3Packages: with python3Packages; [ qtile-extras ];
    };
    windowManager.windowmaker.enable = true;
  };

  services.xserver.xkb = {
    layout = "us,ru";
    options = "grp:alt_shift_toggle";
  };

  services.displayManager.ly = {
    enable = true;
    settings = {
      animation = "doom";
      blank_password = true;
      term_reset_cmd = "tput reset";
      fg = 7;
      bg = 0;
    };
  };

  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  users.users.kris = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "pipewire" "wireshark" ];
    packages = with pkgs; [ tree ];
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;
  programs.firefox.enable = true;
  programs.wireshark.enable = true;
  programs.amnezia-vpn.enable = true;
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      libGL
      mesa
      xorg.libX11
      xorg.libXext
      xorg.libXrender
      xorg.libxcb
      xorg.libXi
      stdenv.cc.cc.lib
      libxkbcommon
    ];
  };

  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    xdg-utils
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  environment.sessionVariables = {
    QT_QPA_PLATFORM              = "wayland";
    NIXOS_OZONE_WL               = "1";
    MOZ_ENABLE_WAYLAND           = "1";
    _JAVA_AWT_WM_NONREPARENTING  = "1";
  };

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "26.05";
}
