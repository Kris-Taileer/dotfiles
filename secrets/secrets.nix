let
  marmar = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP30FsTAhKNGSnDSXIK67xRmeVAzmzAoLzXa88r8hjEO mjarduk@marmar";
  combine = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAUilVTRlmcV57N8IjLN6KNb4ChF2dvf3ZK0dcnmsH2D";

  combineFiles = [ marmar combine ];
in
{
  "combine_garage_keys.age".publicKeys = combineFiles;
  "combine_grafana_secret.age".publicKeys = combineFiles;
}
