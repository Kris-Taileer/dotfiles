{
  description = "My dotfiles!! :D";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager, ... }:
  let
    pkgs = nixpkgs.legacyPackages."x86_64-linux";
  in
  {
    homeConfigurations."mjarduk" = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [ ./home/mjarduk ];
      extraSpecialArgs = { homeDirectory = "/home/mjarduk"; };
    };

    darwinConfigurations."marbook" = nix-darwin.lib.darwinSystem {
      specialArgs = { inherit self home-manager; };
      modules = [ ./hosts/marbook ];
    };
  };
}
