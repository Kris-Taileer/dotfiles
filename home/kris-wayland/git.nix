{ ... }:
{
	programs.git = {
		enable = true;
		userName = "kris";
		userEmail = "taileer.kris0@mail.ru";
		extraConfig = {
			init.defaultBranch = "main";
		};
	};
}
