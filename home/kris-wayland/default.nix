{ config, pkgs, ... }:


{
	imports = [
		./shell.nix
		./git.nix
		./ssh.nix
		./packages.nix
		./desktop.nix
		./desktop-tools.nix
		./screenshot.nix
		./dev.nix
		./terminal.nix
		./waybar.nix
		./hyprland.nix
		./osu.nix
	];
	home.username = "kris";
	home.homeDirectory = "/home/kris";
	home.stateVersion = "26.05";
}
