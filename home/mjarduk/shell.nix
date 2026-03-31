{ ... }:
{
  programs.zsh = {
    enable = true;

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];
      theme = "lambda";
    };

    shellAliases = {
      switch = "nix run home-manager/master -- switch --flake ~/dots#mjarduk";
    };

    initContent = ''
      export PATH="$HOME/.local/bin:$PATH"
    '';
  };
}
