{ ... }:
{
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;

    shellAliases = {
      ll = "ls -la";
      ".." = "cd ..";
      rebuild = "nh os switch ~/nixos-dotfiles";
      clean = "nh clean all";
      rebuild-nom = "sudo nixos-rebuild switch --flake ~/nixos-dotfiles#nixos-btw |& nom";
    };

    oh-my-zsh = {
      enable = true;
      theme = "agnoster";
      plugins = [ "git" "sudo" "direnv" ];
    };

    history = {
      size = 10000;
      ignoreDups = true;
    };
  };

  programs.tmux = {
    enable = true;
    shortcut = "a";
    terminal = "screen-256color";
    historyLimit = 10000;
    extraConfig = ''
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R
      set -g mouse on
      set -g status-style "bg=#0d0e1a,fg=#f5f3ff"
      set -g status-left "#[fg=#b15cff,bold] #S "
      set -g status-right "#[fg=#5ef1ff] %H:%M #[fg=#39ff9e] %d/%m/%Y "
      set -g window-status-current-style "fg=#ff5fc4,bold"
    '';
  };
}
