let
  marmar = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP30FsTAhKNGSnDSXIK67xRmeVAzmzAoLzXa88r8hjEO mjarduk@marmar";
in
{
  "combine_keys.age".publicKeys = [ marmar ];
}
