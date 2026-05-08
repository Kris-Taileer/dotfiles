{
  description = "My dotfiles!! :D";

  inputs = {
    nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs-unstable";

    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager-unstable = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager, home-manager-unstable, agenix, ... }:
  let
    commonSettings = {
      username = "mjarduk";
      sshPubkeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP30FsTAhKNGSnDSXIK67xRmeVAzmzAoLzXa88r8hjEO mjarduk@marmar"
        "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIBn0hysw8HdKRBT8500YrZwP0mqi1vrPztQxnbMkBuNEAAAABHNzaDo= mjarduk@gmail.com"
      ];
      password = "$6$FvuFvW5la529F.tQ$KG9jPlANaLVqw/L9MxsGii25oGQzY6LMoTTwmQeMlmV6vvT/0vGczIomIvPisC4tg9Z0tklrlkYqx6SKrMgkJ.";
      bareMetal = false;
    };
  in{
    homeConfigurations."mjarduk" = let
      pkgs = nixpkgs.legacyPackages."x86_64-linux";
    in home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = { homeDirectory = "/home/mjarduk"; inherit inputs; };
      modules = [
        agenix.homeManagerModules.default
        ./home/mjarduk
      ];
    };

    darwinConfigurations."marbook" = nix-darwin.lib.darwinSystem {
      specialArgs = { inherit self inputs; home-manager = home-manager-unstable; };
      modules = [ ./hosts/marbook ];
    };

    nixosConfigurations = {
      combine = let
        settings = commonSettings // {
          hostname = "combine";
          vpnPort =   46780;
        };
      in nixpkgs.lib.nixosSystem {
        specialArgs = { inherit settings; };
        modules = [
          { nixpkgs.hostPlatform = "x86_64-linux"; }
          ./hosts/server/generic
          ./hosts/server/generic/vmwguest.nix
          ./hosts/server/combine
          ./hardware/combine.nix
          agenix.nixosModules.default
        ];
      };
      minecraft = let
        settings = commonSettings // {
          hostname = "minecraft";
        };
      in nixpkgs.lib.nixosSystem {
        specialArgs = { inherit settings; };
        modules = [
          { nixpkgs.hostPlatform = "x86_64-linux"; }
          ./hosts/server/generic
          ./hosts/server/generic/vmwguest.nix
          ./host/minecraft
          ./hardware/minecraft.nix
          agenix.nixosModules.default
        ];
      };
    };
  };
}
