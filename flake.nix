{
  description = "LiveBeats";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        # pkgs = nixpkgs.legacyPackages.${system};
        pkgs = import nixpkgs { inherit system; };

      in
      rec {
        packages = {
          live-beats = pkgs.callPackage ./pkgs/live-beats { inherit pkgs self; };
          default = packages.live-beats;
        };


        devShells = {
          default = devShells.dev;

          dev = import ./pkgs/dev-shell {
            inherit pkgs;
            db_name = "db_dev";
            # MIX_ENV = "dev";
          };
          # test = import .pkgs/dev-shell {
          #   inherit pkgs;
          #   db_name = "db_test";
          #   MIX_ENV = "test";
          # };
          # prod = import .pkgs/dev-shell {
          #   inherit pkgs;
          #   db_name = "db_prod";
          #   MIX_ENV = "prod";
          # };
        };

        checks = {
          flake-build = packages.default;

          test = pkgs.runCommandLocal "test-hello" { } ''
            # ${packages.default}/bin/${packages.default.name} > $out
            mix test
          '';
        };

        formatter = pkgs.nixpkgs-fmt;
      });
}
