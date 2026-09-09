{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/asus-numberpad-driver.nix
    ../../modules/minecraft-server.nix
    ../../modules/bluetooth.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 3;

  boot.tmp.useTmpfs = true;
  boot.tmp.tmpfsSize = "25%";

  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
    "vm.dirty_ratio" = 10;
    "vm.dirty_background_ratio" = 5;
    "vm.dirty_expire_centisecs" = 1500;
    "vm.dirty_writeback_centisecs" = 500;
    "net.core.somaxconn" = 4096;
  };

  services.journald.extraConfig = ''
    SystemMaxUse=100M
    MaxRetentionSec=1week
  '';

  nix.settings.max-jobs = "auto";
  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 3d";
  };
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

  environment.etc."ly/black_hole.dur".source = ./black_hole.dur;

  services.displayManager.ly = {
    enable = true;
    settings = {
      animation = "dur_file";
      dur_file_path = "/etc/ly/black_hole.dur";
      blank_password = true;
      term_reset_cmd = "tput reset";
      fg = "0x00FFFFFF"; # white
      bg = "0x00000000"; # black
      bigclock = "en";
      bigclock_12hr = false;
      bigclock_seconds = true;
    };
  };

  services.pipewire = {
    enable = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  programs.dconf.enable = true;
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.hyprlock = {};

  services.couchdb = {
    enable = true;
    adminUser = "admin";
    adminPass = "katarsis16";

    bindAddress = "0.0.0.0";
    port = 5984;
  };

  users.users.kris = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "pipewire" "wireshark" "docker" "video" "libvirtd" "vboxusers" ];
    packages = with pkgs; [ tree ];
    shell = pkgs.zsh;
  };

  programs.zsh.enable = true;
  programs.wireshark.enable = true;
  programs.amnezia-vpn.enable = true;

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    extraCompatPackages = with pkgs; [ proton-ge-bin ];
  };
  programs.gamemode.enable = true;

  services.marcraft = {
    enable = true;
    dataDir = "/srv/minecraft";
    openFirewall = true;
    port = 25565;

    javaPackage = pkgs.jdk25;
    jvmFlags = [
      "-Xms4G"
      "-Xmx8G"
      "-XX:+UseZGC"
      "-XX:+UseCompactObjectHeaders"
      "-XX:+UseStringDeduplication"
    ];
  };

  services.bluetooth-setup = {
    enable = true;
    user = "kris";
  };

  services.asus-numberpad-driver = {
    enable = true;
    layout = "up5401ea";
    wayland = true;
    waylandDisplay = "wayland-1";
    runtimeDir = "/run/user/1000/";
  };


  virtualisation.docker.enable = true;
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;
  virtualisation.virtualbox.host.enable = true;
  virtualisation.virtualbox.host.enableExtensionPack = true;

  services.tailscale.enable = true;
  services.openssh.enable = true;

  # Dedicated tunnel to the VPS (77.91.87.139) so the Minecraft server (behind CGNAT
  # here) is reachable through the VPS's public IP, independent of Amnezia's own
  # WireGuard/AmneziaWG stack running there.
  networking.wg-quick.interfaces.wg-mc = {
    address = [ "10.23.42.2/30" ];
    privateKeyFile = "/etc/wg-mc-private.key";
    peers = [{
      publicKey = "oip22r8rzfM4kEEgP2dnvKSiQsX82kYsXXtmk0X13gE=";
      endpoint = "77.91.87.139:51888";
      allowedIPs = [ "10.23.42.1/32" ];
      persistentKeepalive = 25;
    }];
  };

  security.pki.certificateFiles = [ ./certs/letoctf-root-ca.pem ];
  services.desktopManager.plasma6.enable = true;

  programs.driftwm.enable = true;

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      libGL
      mesa
      libx11
      libxext
      libxrender
      libxcb
      libxcb-util
      libxcb-cursor
      xorg.xcbutilwm
      xorg.xcbutilimage
      xorg.xcbutilkeysyms
      xorg.xcbutilrenderutil
      wayland
      libxi
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
