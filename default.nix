{ lib, infuse, ... }:
{
  default-config = "${./default-config.json}";
  profiles = import ./profiles.nix { inherit infuse; };
  ociImage = lib.strings.trim (builtins.readFile ./oci-image.txt);
}
