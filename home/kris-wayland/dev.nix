{ pkgs, lib, ... }:
{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # LazyVim's git UI (<leader>gg). Other LazyVim deps (git, gcc, make, ripgrep,
  # fd, nodejs, unzip, Nerd font) are already in packages.nix / fonts.
  home.packages = [ pkgs.lazygit ];

  # Bootstrap the LazyVim starter into ~/.config/nvim. It must be WRITABLE
  # (lazy.nvim manages plugins + lazy-lock.json at runtime, so it can't be a
  # read-only home.file store symlink). Runs only when there's no config yet;
  # backs up anything already present so nothing is clobbered.
  home.activation.lazyvim = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    nvimdir="$HOME/.config/nvim"
    if [ ! -e "$nvimdir/init.lua" ]; then
      [ -e "$nvimdir" ] && mv "$nvimdir" "$nvimdir.bak.$(date +%s)"
      ${pkgs.git}/bin/git clone --depth 1 https://github.com/LazyVim/starter "$nvimdir"
      rm -rf "$nvimdir/.git"
    fi
  '';
}
