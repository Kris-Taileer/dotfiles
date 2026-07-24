{
	description = "NixOS from Hell";
	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
		home-manager = {
			url = "github:nix-community/home-manager/master";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		driftwm.url = "github:malbiruk/driftwm";
		zen-browser = {
			url = "github:0xc000022070/zen-browser-flake";
			inputs.nixpkgs.follows = "nixpkgs";
		};
	};

	outputs = { self, nixpkgs, home-manager, driftwm, zen-browser, ... }@inputs: {
		nixosConfigurations.nixos-btw = nixpkgs.lib.nixosSystem {
			system = "x86_64-linux";
			modules = [
				./hosts/nixos-btw/configuration.nix
				./modules/asus-numberpad-driver.nix
				./modules/minecraft-server.nix
				driftwm.nixosModules.default
				home-manager.nixosModules.home-manager
				{
					home-manager = {
						useGlobalPkgs = true;
						useUserPackages = true;
						extraSpecialArgs = { inherit inputs; };
						users.kris = import ./home/default.nix;
						backupFileExtension = "backup";
					};
				}
			];

		};
	};
}
