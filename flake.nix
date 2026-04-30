{
  description = "My dotfiles!! :D";

  inputs = {
    nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, ... }:
  let
    commonSettings = {
      username = "mjarduk";
      sshPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP30FsTAhKNGSnDSXIK67xRmeVAzmzAoLzXa88r8hjEO mjarduk@marmar";
      password = "$6$FvuFvW5la529F.tQ$KG9jPlANaLVqw/L9MxsGii25oGQzY6LMoTTwmQeMlmV6vvT/0vGczIomIvPisC4tg9Z0tklrlkYqx6SKrMgkJ.";
      bareMetal = false;
    };
  in{
    homeConfigurations."mjarduk" = let
      pkgs = nixpkgs.legacyPackages."x86_64-linux";
    in home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [ ./home/mjarduk ];
      extraSpecialArgs = { homeDirectory = "/home/mjarduk"; };
    };

    darwinConfigurations."marbook" = nix-darwin.lib.darwinSystem {
      specialArgs = { inherit self home-manager; };
      modules = [ ./hosts/marbook ];
    };

    nixosConfigurations = {
      combine = let
        settings = commonSettings // {
          hostname = "combine";
        };
      in nixpkgs.lib.nixosSystem {
        specialArgs = { inherit settings; };
        modules = [
          { nixpkgs.hostPlatform = "x86_64-linux"; }
          ./hosts/server/generic
          ./hosts/server/generic/vmwguest.nix
          ./hosts/server/combine.nix
          ./hardware/combine.nix
        ];
      };
    };
  };
}
