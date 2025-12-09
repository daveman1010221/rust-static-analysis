{
  description = "static analysis tools for Polar";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils"; # Utility functions for Nix flakes
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; # Main Nix package repository
    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";

    l3x.url = "github:daveman1010221/l3x?dir=l3x"; # l3x repo with nix support
      l3x.inputs.nixpkgs.follows = "nixpkgs";
      l3x.inputs.flake-utils.follows = "flake-utils";
  };

  outputs = { self, flake-utils, nixpkgs, rust-overlay, l3x, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ rust-overlay.overlays.default ];
        };

        rustToolChain = pkgs.rust-bin.nightly.latest.default;

        rustPlatform = pkgs.makeRustPlatform {
          cargo = rustToolChain;
          rustc = rustToolChain;
        };

        audit = rustPlatform.buildRustPackage rec {
          pname = "cargo-audit";
          version = "0.21.2";
          src = pkgs.fetchCrate {
            inherit pname version;
            hash = "sha256-bRBQpZ0YoKDh959a1a7+qEs2vh+dbP8vYcwbkNZQ5cQ=";
          };
          cargoHash = "sha256-MIwKgQM3LoNV9vcs8FfxTzqXhIhLkYd91dMEgPH++zk=";
        };

        auditable = rustPlatform.buildRustPackage rec {
          pname = "cargo-auditable";
          version = "0.6.7";
          src = pkgs.fetchCrate {
            inherit pname version;
            hash = "sha256-VUyIliP0j/r1vxR7c82Aenn6gtTQJnl+W6dXjirzbVY=";
          };
          cargoHash = "sha256-W0FivJVR7bwCrLHDtMrVZ0p4fJMNcu1p+mEFYE7HfM4=";
          doCheck = false; # turn off package checks (which don't work in the nix environment)
        };

        bloat = rustPlatform.buildRustPackage rec {
          pname = "cargo-bloat";
          version = "0.12.1";
          src = pkgs.fetchCrate {
            inherit pname version;
            hash = "sha256-9uWQNaRt5U09YIiAFBLUgcHWm2vg2gazSjtwR1+It3M=";
          };
          cargoHash = "sha256-8Omw8IsmoFYPBB6q1EAAbcBhTjBWfCChV2MhX9ImY8Y=";

        };

        semvers = rustPlatform.buildRustPackage rec {
          pname = "cargo-semver-checks";
          version = "0.41.0";
          src = pkgs.fetchCrate {
            inherit pname version;
            hash = "sha256-uMZ31UK1eZevSOXSOEx3t1PdNQI74R5To+sjJl/eWd8=";
          };
          cargoHash = "sha256-8VtSQZHR8L6nijcN71ey9nW5nrAsPK6qyqJSWQDz8uw=";
          buildInputs = with pkgs; [
            cmake
            gnumake
          ];
          preHook = ''
            export CMAKE="${pkgs.cmake}/bin/cmake"
            export CMAKE_MAKE_PROGRAM="${pkgs.gnumake}/bin/make"
          '';
          doCheck = false; # turn off package checks (which don't work in the nix environment)
        };

        # this works when you cargo-install it
        spellcheck = rustPlatform.buildRustPackage rec {
          pname = "cargo-spellcheck";
          version = "0.15.5";
          src = pkgs.fetchCrate {
            inherit pname version;
            hash = "sha256-3kA2CXkyJTr6i8zmKIcmau2FxbRMPiUOd7TYeHHGoAI=";
          };
          cargoHash = "sha256-rYYOBuuBL2kyek4DdKaCkQQPvptSLXYm90e6DjoyUW4=";
          buildInputs = with pkgs; [
            libclang
          ];
          preHook = ''
            export LIBCLANG_PATH="${pkgs.libclang.lib}/lib/"
          '';
          doCheck = false; # turn off package checks (which don't work in the nix environment)
        };

        deny = rustPlatform.buildRustPackage rec {
          pname = "cargo-deny";
          version = "0.18.2";
          src = pkgs.fetchCrate {
            inherit pname version;
            hash = "sha256-AijD8az86arU8AunymD3+p9rfcNN/5S499JBCpAVoiA=";
          };
          cargoHash = "sha256-3fCACetvO9KRjoTh3V41+vhWFjwaNtoHZ/Zh+Zxmxlc=";
          doCheck = false; # turn off package checks (which don't work in the nix environment)
        };

        # TODO: finish this
        cargoCycloneDx = rustPlatform.buildRustPackage rec {
          pname = "cargo-cyclonedx";
          version = "0.5.7";
          src = pkgs.fetchCrate {
            inherit pname version;
            hash = "sha256-EezOYkG5UHBixl35pj2u1jEPriDUIXO4xRMrVAzjghE=";
          };
          cargoHash = "sha256-NRZifMDglVZjO+r7w/ZANxNQPIkfPYlLTEzc2Nar2Dw=";

          doCheck = false; # turn off package checks (which don't work in the nix environment)
        };

        staticToolsScript = pkgs.writeShellScriptBin "static-tools.sh" ''
#!${pkgs.bash}/bin/bash
# Call the script from the flake source tree
exec ''${./scripts/static-tools.sh} "$@"
        '';

        # unusedfeatures = rustPlatform.buildRustPackage rec {
        #   pname = "cargo-unused-features";
        #   version = "0.2.0";
        #   src = pkgs.fetchCrate {
        #     inherit pname version;
        #     hash = "sha256-gdwIbbQDw/DgBV9zY2Rk/oWjPv1SS/+oFnocsMo2Axo=";
        #   };
        #   cargoHash = "sha256-IiS4d6knNKqoUkt0sRSJ+vNluqllS3mTsnphrafugIo=";

        #   nativeBuildInputs = with pkgs; [
        #     rustToolChain
        #     openssl
        #     openssl.dev
        #     pkg-config
        #   ];
        #   buildInputs = with pkgs; [
        #     openssl
        #     openssl.dev
        #     pkg-config
        #   ];
        # };

        in {
          packages.default = pkgs.symlinkJoin {
            name = "polar-static-analysis-tools";
            paths = with pkgs; [
              audit
              auditable
              bloat
              semvers
              spellcheck
              noseyparker
              cargo-udeps
              deny
              cargoCycloneDx
              #unusedfeatures
              l3x.packages.${system}.default
              staticToolsScript
            ];
          };
        }

    );
}
