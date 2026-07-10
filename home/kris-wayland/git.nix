{ ... }:
{
	programs.git = {
		enable = true;
		settings = {
			user.name = "kris";
			user.email = "taileer.kris0@mail.ru";
			init.defaultBranch = "main";
		};
	};
}
