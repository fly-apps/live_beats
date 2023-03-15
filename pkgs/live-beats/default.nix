{ self, pkgs }:

with pkgs;
let
  beamPackages = beam.packagesWith beam.interpreters.erlangR24;
in
beamPackages.mixRelease rec {
  pname = "live-beats";
  version = "0.0.0";
  # "self" defaults to the root of your project.
  # amend the path if it is non-standard with `self + "/src";`, for example
  src = self;
  MIX_ENV = "prod";

  LANG = "en_US.UTF-8";
  LANGUAGE = "en_US:en";
  LC_ALL = "en_US.UTF-8";

  ECTO_IPV6 = "true";
  ERL_AFLAGS = "-proto_dist inet6_tcp";

  mixNixDeps = import ./../deps { inherit lib beamPackages; };

  buildInputs = [
    esbuild
    nodePackages.tailwindcss
  ];

  MIX_ESBUILD_PATH = esbuild;
  MIX_TAILWIND_PATH = nodePackages.tailwindcss;

  # For phoenix framework you can uncomment the lines below.
  # For external task you need a workaround for the no deps check flag.
  # https://github.com/phoenixframework/phoenix/issues/2690
  # You can also add any post-build steps here. It's just bash!
  preBuild = ''
    # TODO: fix tailwind and esbuild
    # mix do deps.loadpaths --no-deps-check, tailwind default --minify
    # mix do deps.loadpaths --no-deps-check, esbuild default --minify

    mix phx.digest --no-deps-check
  '';
}

