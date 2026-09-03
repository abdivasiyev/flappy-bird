{
  description = "Flappy Bird game";
  nixConfig = {
    allow-import-from-derivation = true;
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    # Git hooks
    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    pre-commit-hooks,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        inherit (self.checks.${system}) pre-commit-check;
        pkgs = nixpkgs.legacyPackages.${system};
        hpkgs = pkgs.haskell.packages."ghc912";
      in {
        # Tests and suites for this repo
        checks = {
          pre-commit-check = pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              fourmolu.enable = true;
              fourmolu.package = hpkgs.fourmolu;
              hlint.enable = true;
              hlint.package = hpkgs.hlint;
              alejandra.enable = true;
            };
          };
        };

        devShells.default = pkgs.callPackage ./shell.nix {inherit pkgs hpkgs pre-commit-hooks pre-commit-check;};
      }
    );
}
