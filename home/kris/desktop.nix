{ config, ... }:
{
	home.file.".config/qtile".source = ./qtile;
	home.file."wallpaper.jpg".source = ./wallpapers/wallpaper.png;
}
