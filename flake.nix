{
	description = "NixOS from Hell";
	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
		home-manager = {
			url = "github:nix-community/home-manager/master";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		driftwm.url = "github:malbiruk/driftwm";
	};

	outputs = { self, nixpkgs, home-manager, driftwm, ... }: {
		nixosConfigurations.nixos-btw = nixpkgs.lib.nixosSystem {
			system = "x86_64-linux";
			modules = [
				./hosts/nixos-btw/configuration.nix
				./modules/asus-numberpad-driver.nix
				driftwm.nixosModules.default
				home-manager.nixosModules.home-manager
				{
					home-manager = {
						useGlobalPkgs = true;
						useUserPackages = true;
						users.kris = import ./home/default.nix;
						backupFileExtension = "backup";
					};
				}
			];

		};
	};
}
