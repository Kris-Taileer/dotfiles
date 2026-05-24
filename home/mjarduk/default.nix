{ pkgs, homeDirectory, inputs, ... }:
{
  home.username = "mjarduk";
  home.homeDirectory = homeDirectory;
  home.stateVersion = "25.11";

  imports = [
    ./shell.nix
    ./git.nix
    ./ssh.nix
  ];

  # Global packages that do not require complex Nix expressions
  home.packages = with pkgs; [
    nixd
    nil
    nixfmt
    dosbox-x
    inputs.agenix.packages.${pkgs.system}.default
  ];

  programs.home-manager.enable = true;
}
