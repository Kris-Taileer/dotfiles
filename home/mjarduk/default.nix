{ pkgs, ... }:
{
  home.username = "mjarduk";
  home.homeDirectory = "/home/mjarduk";
  home.stateVersion = "25.11";

  imports = [
    ./shell.nix
  ];

  # Global packages that do not require complex Nix expressions
  home.packages = with pkgs; [
    nixd
    nil
    nixfmt
  ];

  programs.home-manager.enable = true;
}
