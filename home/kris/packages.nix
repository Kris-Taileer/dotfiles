{ pkgs,  ... }:
{
	home.packages = with pkgs; [
                fastfetch
                python3
                gcc
                nixpkgs-fmt
                nodejs
                neovim
                ghidra
		rofi
		pkgs.ayugram-desktop
        ];

}
