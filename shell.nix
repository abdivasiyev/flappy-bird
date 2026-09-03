{
  pkgs ? let
    lock = (builtins.fromJSON (builtins.readFile ./flake.lock)).nodes.nixpkgs.locked;
    nixpkgs = fetchTarball {
      url = "https://github.com/nixos/nixpkgs/archive/${lock.rev}.tar.gz";
      sha256 = lock.narHash;
    };
  in
    import nixpkgs {overlays = [];},
  hpkgs ? pkgs.haskell.packages."ghc912",
  pre-commit-check,
  ...
}:
pkgs.stdenv.mkDerivation {
  name = "flappy-bird-dev";

  # Build time dependencies
  nativeBuildInputs = [
    hpkgs.ghc
    hpkgs.ghcid
    hpkgs.cabal-install
    hpkgs.cabal-gild
    hpkgs.hoogle
    hpkgs.haskell-language-server
    hpkgs.fourmolu
    hpkgs.hlint
    pkgs.just
  ];

  # Runtime dependencies
  buildInputs = [
    pre-commit-check.enabledPackages
    pkgs.git
    pkgs.pkg-config
    pkgs.SDL2
    pkgs.SDL2_image
    pkgs.libtiff
  ];
  # Things to run before entering devShell
  shellHook = ''
    ${pre-commit-check.shellHook}
  '';

  # Environmental variables
  NIX_CONFIG = "extra-experimental-features = nix-command flakes";
}
