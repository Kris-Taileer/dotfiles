{ ... }: {
  programs.ssh = {
    enable = true;

    matchBlocks = {
      combine = {
        host = "combine";
        hostname = "192.168.125.125";
        user = "mjarduk";
        identityFile = "~/.ssh/id_ed25519_sk_rk";
      };
      "*" = {
        setEnv = {
          TERM = "xterm-256color";
        };
      };
    };
  };
}
