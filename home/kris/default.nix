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
	programs.git.enable = true;
	home.stateVersion = "26.05";
}
