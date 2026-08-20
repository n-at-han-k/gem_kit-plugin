{
  description = "gem_kit-plugin — a worked example of extending `gem kit`";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Gemfile.lock pins the gems and gemset.nix says where nix fetches each
        # one. Regenerate the latter with `bundix -l` after touching either.
        gems = pkgs.bundlerEnv {
          name = "gem-kit-plugin-gems";
          ruby = pkgs.ruby_3_4;
          gemfile = ./Gemfile;
          lockfile = ./Gemfile.lock;
          gemset = ./gemset.nix;
        };
      in
      {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = [ pkgs.pkg-config ];
          buildInputs = with pkgs; [
            bundix
            gems
            gems.wrappedRuby
            libyaml
            openssl
            trufflehog
          ];

          shellHook = ''
            # A pre-commit hook runs with a minimal environment, and Ruby then
            # defaults to US-ASCII — which turns every em dash in these sources
            # into "invalid byte sequence" the moment a file is read.
            export LANG="''${LANG:-C.UTF-8}"
            export LC_ALL="''${LC_ALL:-$LANG}"

            # This gem is not in the bundle — it is the repository — so put its
            # lib/ on the load path and let `require "gem_kit/plugin"` find the
            # working tree.
            export RUBYLIB="$PWD/lib''${RUBYLIB:+:$RUBYLIB}"

            if [ ! -f .git/hooks/pre-commit ]; then
              bundle exec lefthook install
            fi
          '';
        };
      }
    );
}
