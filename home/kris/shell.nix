{ ... }:
{
	programs.zsh = {
		enable = true;
		autosuggestion.enable = true;
		syntaxHighlighting.enable = true;
		enableCompletion = true;
		shellAliases = {
			ll = "ls -la";
			".." = "cd ..";
		};
		oh-my-zsh = {
			enable = true;
			theme= "agnoster";
			plugins = [ "git" "sudo" ];
		};	
		history ={
			size = 10000;
			ignoreDups = true;
		};
	};
}
