{ config, pkgs, ... }:
{
  home.pointerCursor = {
    package = pkgs.catppuccin-cursors.mochaMauve;
    name    = "catppuccin-mocha-mauve-cursors";
    size    = 48;
    gtk.enable = true;
    x11.enable = true;
  };
  xdg.dataFile."applications/ida-pro.desktop".text = ''
    [Desktop Entry]
    Name=IDA Pro
    Exec=/home/kris/ida-pro-9.3/ida
    Icon=/home/kris/ida-pro-9.3/appico.png
    Terminal=false
    Type=Application
    Categories=Development;Debugger;
  '';

  xdg.dataFile."applications/nvim-term.desktop".text = ''
    [Desktop Entry]
    Name=Neovim
    Exec=alacritty -e nvim %F
    Terminal=false
    Type=Application
    MimeType=text/plain;text/x-python;text/x-csrc;text/x-chdr;text/javascript;application/json;text/x-shellscript;text/x-lua;text/x-rust;text/markdown;text/css;text/x-makefile;
  '';

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory"                = "dolphin.desktop";

      "image/jpeg"                     = "imv.desktop";
      "image/png"                      = "imv.desktop";
      "image/gif"                      = "imv.desktop";
      "image/webp"                     = "imv.desktop";
      "image/bmp"                      = "imv.desktop";
      "image/tiff"                     = "imv.desktop";
      "image/svg+xml"                  = "imv.desktop";
      "video/mp4"                      = "mpv.desktop";
      "video/webm"                     = "mpv.desktop";
      "video/x-matroska"               = "mpv.desktop";
      "video/x-msvideo"                = "mpv.desktop";
      "video/quicktime"                = "mpv.desktop";
      "audio/mpeg"                     = "mpv.desktop";
      "audio/ogg"                      = "mpv.desktop";
      "audio/flac"                     = "mpv.desktop";
      "audio/wav"                      = "mpv.desktop";
      "audio/aac"                      = "mpv.desktop";
      "audio/x-wav"                    = "mpv.desktop";
      "application/pdf"                = "org.pwmt.zathura.desktop";
      "application/zip"                = "ark.desktop";
      "application/x-tar"              = "ark.desktop";
      "application/gzip"               = "ark.desktop";
      "application/x-7z-compressed"    = "ark.desktop";
      "application/x-rar"              = "ark.desktop";
      "application/x-bittorrent"       = "org.qbittorrent.qBittorrent.desktop";
      "x-scheme-handler/magnet"        = "org.qbittorrent.qBittorrent.desktop";
      "text/plain"                     = "dev.zed.Zed.desktop";
      "text/x-python"                  = "dev.zed.Zed.desktop";
      "text/x-csrc"                    = "dev.zed.Zed.desktop";
      "text/x-chdr"                    = "dev.zed.Zed.desktop";
      "text/javascript"                = "dev.zed.Zed.desktop";
      "application/json"               = "dev.zed.Zed.desktop";
      "text/x-shellscript"             = "dev.zed.Zed.desktop";
      "text/x-lua"                     = "dev.zed.Zed.desktop";
      "text/x-rust"                    = "dev.zed.Zed.desktop";
      "text/markdown"                  = "dev.zed.Zed.desktop";
      "text/css"                       = "dev.zed.Zed.desktop";
    };
  };
	home.file.".config/qtile".source = ./qtile;
	home.file."wallpaper.png".source = ./wallpapers/wallpaper.png;
	home.file.".config/waypaper/config.ini".text = ''
		[Settings]
		folder = ~/
		wallpaper = ~/wallpaper.png
		backend = swaybg
		monitors = All
		fill = fill
		sort = name
		color = #ffffff
		subfolders = False
		show_hidden = False
		show_keywords = False
		randomize = False
		number_of_columns = 4
	'';
}
