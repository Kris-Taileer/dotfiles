{ config, pkgs, ... }:
{
  programs.zsh = {
    enable = true;

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];
      theme = "lambda";
    };

    shellAliases = {
      switch = "home-manager switch --flake ${config.home.homeDirectory}/dots#mjarduk; omz reload";
      switch-darwin = "sudo darwin-rebuild switch --flake ${config.home.homeDirectory}/dots#marbook; omz reload";
    };

    initContent = ''
      ${pkgs.lib.optionalString pkgs.stdenv.isDarwin ''
        eval "$(/opt/homebrew/bin/brew shellenv)"
      ''}
      export PATH="$HOME/.local/bin:$PATH"
    '';
  };
}
