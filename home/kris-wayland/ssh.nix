{ ... }:

{
	programs.ssh = {
		enable = true;
		matchBlocks = {
			"kris-box" = {
				hostname = "188.35.23.159";
				user = "kris";
			};
		};
	};
}
