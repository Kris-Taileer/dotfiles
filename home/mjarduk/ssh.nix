{ ... }: {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    settings = {
      combine = {
        HostName = "192.168.125.125";
        User = "mjarduk";
      };
      git = {
        HostName = "192.168.125.125";
        Port = 23231;
        User = "mjarduk";
      };
      "*" = {
        AddKeysToAgent = "no";
        Compression = false;
        ControlMaster = "no";
        ControlPath = "~/.ssh/master-%r@%n:%p";
        ControlPersist = "no";
        ForwardAgent = false;
        HashKnownHosts = false;
        SetEnv = {
          TERM = "xterm-256color";
        };
        ServerAliveCountMax = 3;
        ServerAliveInterval = 0;
        UserKnownHostsFile = "~/.ssh/known_hosts";
        IdentityFile = [
          "~/.ssh/id_ed25519"
          "~/.ssh/id_ed25519_sk_rk"
        ];
      };
    };
  };
}
