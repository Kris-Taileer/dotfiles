{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/asus-numberpad-driver.nix
    ../../modules/minecraft-server.nix
    ../../modules/bluetooth.nix
    ../../modules/happ-module.nix
    ../../modules/power.nix
  ];
  services.happ.enable = true;


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

  # Prevent Tiger Lake thermal throttling, which shows up in osu!lazer as
  # periodic micro-stutter. Pairs with gamemode's performance governor.
  services.thermald.enable = true;

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

  # --- Battery: keep these dev daemons configured but NOT autostarted at boot ---
  # They idle-drain (couchdb's beam.smp alone ~2-3% CPU). Docker + libvirtd stay
  # socket-activated (start on first `docker`/virt-manager use). CouchDB and
  # Tailscale start on demand:
  #   systemctl start couchdb
  #   sudo systemctl start tailscaled && sudo tailscale up
  virtualisation.docker.enableOnBoot   = false;
  systemd.services.couchdb.wantedBy    = lib.mkForce [ ];
  systemd.services.libvirtd.wantedBy   = lib.mkForce [ ];
  systemd.services.tailscaled.wantedBy = lib.mkForce [ ];

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

  programs.driftwm.enable = true;

  # macOS-like Wayland compositor. Kept alongside driftwm (both are selectable
  # in ly); Plasma 6 was removed in favour of this lighter setup.
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

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
    pkgs.fetch
    vim
    wget
    git
    xdg-utils
    openvpn
    wireguard-tools
  ];

  fonts.packages = with pkgs; [
    monocraft    # system-wide font (Minecraft-style monospace)
    nerd-fonts.jetbrains-mono
    inter
    nerd-fonts.symbols-only
  ];

  # Monocraft everywhere. Nerd Font kept as fallback so icon glyphs (bar,
  # symbols) that Monocraft lacks still render.
  fonts.fontconfig.defaultFonts = {
    monospace = [ "Monocraft" "JetBrainsMono Nerd Font" ];
    sansSerif = [ "Monocraft" "JetBrainsMono Nerd Font" ];
    serif     = [ "Monocraft" "JetBrainsMono Nerd Font" ];
  };

  environment.sessionVariables = {
    QT_QPA_PLATFORM              = "wayland";
    NIXOS_OZONE_WL               = "1";
    MOZ_ENABLE_WAYLAND           = "1";
    _JAVA_AWT_WM_NONREPARENTING  = "1";
    XCURSOR_THEME                = "macOS";
  };

  nixpkgs.config.allowUnfree = true;

  # xwayland-satellite 0.8.1 (the version in our pinned nixpkgs) panics with
  # "Invalid size for positioner's anchor rectangle" on Ghidra's zero-size splash
  # xdg_positioner and takes the whole X server down with it — so Ghidra's GUI
  # dies during startup under driftwm. 0.8.2 turns SPLASH windows into fixed-size
  # toplevels (no positioner), which removes the crash and makes Ghidra start
  # reliably. Drop this override once our nixpkgs ships xwayland-satellite >= 0.8.2.
  nixpkgs.overlays = [
    (final: prev: {
      xwayland-satellite = prev.xwayland-satellite.overrideAttrs (old: rec {
        version = "0.8.2";
        src = prev.fetchFromGitHub {
          owner = "Supreeeme";
          repo = "xwayland-satellite";
          tag = "v${version}";
          hash = "sha256-Mb7jpqnrcYCfNSItIkkHpuR3YxWFxPuIBfcwNKlRBkk=";
        };
        cargoDeps = prev.rustPlatform.fetchCargoVendor {
          inherit src;
          name = "xwayland-satellite-${version}-vendor";
          hash = "sha256-Saa3SRsQuY6u6pfBGezaEExOt/ReblnrG7pAXjA6Dk8=";
        };
      });
    })
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "26.05";
}
