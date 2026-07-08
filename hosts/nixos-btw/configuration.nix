{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/asus-numberpad-driver.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 3;
  networking.firewall.allowedTCPPorts = [ 5984 ];
  networking.firewall.trustedInterfaces = [ "tailscale0" ];
  networking.hostName = "nixos-btw";
  networking.hosts = {
    "127.0.0.1"      = [ "localhost" ];
    "::1"            = [ "localhost" ];
    "127.0.0.2"      = [ "nixos-btw" ];
    "160.30.99.189"  = [ "chal" ];
  };
  networking.networkmanager.enable = true;
  networking.networkmanager.dns = "systemd-resolved";
  networking.networkmanager.plugins = with pkgs; [ networkmanager-openvpn ];
  networking.firewall.enable = true;

  time.timeZone = "Europe/Moscow";
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;
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
    desktopManager.plasma6.enable = true;
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
      clock = "%H:%M:%S";
    };
  };

  services.pipewire = {
    enable = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  services.couchdb = {
    enable = true;
    adminUser = "admin";
    adminPass = "katarsis16";

    bindAddress = "0.0.0.0";
    port = 5984;
  };

  users.users.kris = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "pipewire" "wireshark" "docker" "video" "libvirtd" ];
    packages = with pkgs; [ tree ];
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;
  programs.firefox.enable = true;
  programs.wireshark.enable = true;
  programs.amnezia-vpn.enable = true;

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    extraCompatPackages = with pkgs; [ proton-ge-bin ];
  };
  programs.gamemode.enable = true;

  services.asus-numberpad-driver = {
    enable = true;
    layout = "up5401ea";
    wayland = true;
    waylandDisplay = "wayland-0";
    runtimeDir = "/run/user/1000/";
  };


  virtualisation.docker.enable = true;
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;

  services.tailscale.enable = true;
  services.openssh.enable = true;

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      libGL
      mesa
      xorg.libX11
      xorg.libXext
      xorg.libXrender
      xorg.libxcb
      xorg.xcbutil
      xorg.xcbutilcursor
      xorg.libXi
      stdenv.cc.cc.lib
      libxkbcommon
      fontconfig
      freetype
      zlib
      glib
      dbus
      expat
      openssl
    ];
  };

  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    xdg-utils
    openvpn
    wireguard-tools
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  environment.sessionVariables = {
    QT_QPA_PLATFORM              = "wayland";
    NIXOS_OZONE_WL               = "1";
    MOZ_ENABLE_WAYLAND           = "1";
    _JAVA_AWT_WM_NONREPARENTING  = "1";
    XCURSOR_THEME                = "catppuccin-mocha-mauve-cursors";
  };

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "26.05";
}
