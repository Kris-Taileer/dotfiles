{ pkgs, settings, ... }:
{
  nix = {
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
  nix.settings.auto-optimise-store = true;

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

  system.stateVersion = "25.11";
}
