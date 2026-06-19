{ config, pkgs, ... }:


{
	imports = [
		./shell.nix
		./git.nix
		./packages.nix
		./desktop.nix
	];
	home.username = "kris";
	home.homeDirectory = "/home/kris";
	home.stateVersion = "26.05";
}
