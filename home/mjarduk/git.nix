{ ... }:
{
  programs.git = {
    enable = true;
    settings = {
      core.excludesfile = "~/.gitignore";
    };
  };

  home.file = {
    ".gitignore" = {
      text = ''
        .DS_Store
      '';
    };
  };
}
