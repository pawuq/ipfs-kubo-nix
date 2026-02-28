{
  description = "IPFS Kubo Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    infuse = {
      url = "git+https://codeberg.org/amjoseph/infuse.nix?ref=refs/tags/v2.4";
      flake = false;
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      perSystem =
        { pkgs, ... }:
        {
          formatter = pkgs.nixfmt-tree;
        };
      flake = {
        kubo =
          let
            lib = inputs.nixpkgs.lib;
            infuse = (import inputs.infuse { inherit lib; }).v1.infuse;
          in
          import ./default.nix {
            inherit lib;
            inherit infuse;
          };
      };
    };
}
