{ config, pkgs, ... }:


{
	imports = [
		./shell.nix
		./git.nix
		./packages.nix
		./desktop.nix
		./desktop-tools.nix
		./dev.nix
		./terminal.nix
		./waybar.nix
	];
	home.username = "kris";
	home.homeDirectory = "/home/kris";
	home.stateVersion = "26.05";
}
