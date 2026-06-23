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

  services.xserver = {
    enable = true;
    autoRepeatDelay = 200;
    autoRepeatInterval = 35;
    windowManager.qtile = {
      enable = true;
      extraPackages = python3Packages: with python3Packages; [ qtile-extras ];
    };
  };

  services.xserver.xkb = {
    layout = "us,ru";
    options = "grp:alt_shift_toggle";
  };

  services.displayManager.ly = {
    enable = true;
    settings = {
      animation      = "doom";
      blank_password = true;
      term_reset_cmd = "tput reset";
      fg             = 7;
      bg             = 0;
    };
  };

  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  users.users.kris = {
    isNormalUser = true;
    extraGroups  = [ "wheel" "networkmanager" "pipewire" "wireshark" ];
    packages     = with pkgs; [ tree ];
    shell        = pkgs.zsh;
  };

  programs.zsh.enable         = true;
  programs.firefox.enable     = true;
  programs.wireshark.enable   = true;
  programs.amnezia-vpn.enable = true;

  environment.systemPackages = with pkgs; [
    vim
    wget
    git
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "26.05";
}
