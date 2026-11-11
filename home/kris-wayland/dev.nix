{ pkgs, lib, ... }:
{
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  home.packages = [ pkgs.lazygit ];

  # Must stay writable — lazy.nvim manages plugins/lazy-lock.json at runtime.
  home.activation.lazyvim = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    nvimdir="$HOME/.config/nvim"
    if [ ! -e "$nvimdir/init.lua" ]; then
      [ -e "$nvimdir" ] && mv "$nvimdir" "$nvimdir.bak.$(date +%s)"
      ${pkgs.git}/bin/git clone --depth 1 https://github.com/LazyVim/starter "$nvimdir"
      rm -rf "$nvimdir/.git"
    fi
  '';
}
