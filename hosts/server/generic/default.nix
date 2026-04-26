{ pkgs, settings, lib, ... }:
{
  nix = {
    settings = {
      max-jobs = "auto";
      auto-optimise-store = true;
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };

    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
    '';
  };

  networking.hostName = settings.hostname;

  users.defaultUserShell = pkgs.zsh;
  users.mutableUsers = false;
  users.users.${settings.username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      settings.sshPubkey
    ];
  };

  programs.zsh = {
    enable = true;
    oh-my-zsh = {
      enable = true;
      theme = "lambda";
      plugins = [
        "git"
      ];
    };
  };

  services.fstrim.enable = true;
  services.journald.extraConfig = ''
    SystemMaxUse=500M
    MaxRetentionSec=1month
  '';
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      AllowUsers = [ settings.username ];
    };

    extraConfig = lib.optionalString (settings.sshPublic or false) ''
      MaxAuthTries 3
      PerSourcePenalties crash:3600s authfail:3600s max:86400s
    '';
  };

  powerManagement.cpuFreqGovernor = lib.mkIf (settings.bareMetal or false) "performance";

  boot.loader =
    if settings.uefi then
      {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      }
    else
      {
        grub.enable = true;
        grub.device = settings.biosDevice;
      };

  boot.tmp.useTmpfs = true;
  boot.tmp.tmpfsSize = "25%";

  boot.kernelParams = lib.optionals (!(settings.bareMetal or false)) [
    "elevator=none"
  ];

  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
    "net.core.somaxconn" = 4096;
  } // lib.optionalAttrs (settings.bareMetal or false) {
    "kernel.sched_migration_cost_ns" = 5000000;
  };

  system.stateVersion = "25.11";
}
