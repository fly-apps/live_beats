{ pkgs, db_name }:

let
  erlang = pkgs.beam.packages.erlangR24;
  elixir = erlang.elixir.override {
    version = "1.12.3";
    sha256 = "Jo9ZC5cSBVpjVnGZ8tEIUKOhW9uvJM/h84+VcnrT0R0=";
  };
in
pkgs.mkShell {
  name = "live-beats-shell";

  # inherit MIX_ENV;

  buildInputs = [
    elixir
    erlang.elixir_ls
    erlang.hex
    pkgs.mix2nix
    pkgs.postgresql_14
    pkgs.nixpkgs-fmt
    pkgs.nixpkgs-lint
    pkgs.rnix-lsp
    pkgs.overmind
    pkgs.nodePackages.tailwindcss
  ] ++ pkgs.lib.optional pkgs.stdenv.isLinux pkgs.inotify-tools
  ++ pkgs.lib.optionals pkgs.stdenv.isDarwin
    (with pkgs.darwin.apple_sdk.frameworks; [
      CoreFoundation
      CoreServices
    ]);

  shellHook = ''
    # Generic shell variables
    export LANG=en_US.utf-8
    export ERL_AFLAGS="-kernel shell_history enabled"
    export PHX_HOST=localhost
    export FLY_APP_NAME=live_beats
    export RELEASE_COOKIE=UnsecureTestOnlyCookie

    # Postgres
    export DATABASE_URL="ecto://postgres:postgres@localhost:5432/live_beats_prod"
    export POOL_SIZE=15

    # Scope Mix and Hex to the project directory
    mkdir -p .nix-mix
    mkdir -p .nix-hex
    export MIX_HOME=$PWD/.nix-mix
    export HEX_HOME=$PWD/.nix-hex
    export PATH=$MIX_HOME/bin:$PATH
    export PATH=$HEX_HOME/bin:$PATH
  '';
}
