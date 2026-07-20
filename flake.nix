{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    beaker-src = {
      url = "git+https://git.bwaaa.monster/beaker?shallow=0";
      flake = false;
    };
    omnisearch-src = {
      url = "git+https://git.bwaaa.monster/omnisearch?shallow=0";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      beaker-src,
      omnisearch-src
    }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };

          beaker = pkgs.stdenv.mkDerivation {
            pname = "beaker";
            version = "git";
            src = beaker-src;
            makeFlags = [
              "INSTALL_PREFIX=$(out)/"
              "LDCONFIG=true"
            ];
          };
        in
        {
          default = pkgs.stdenv.mkDerivation {
            pname = "omnisearch";
            version = "git";
            src = omnisearch-src;

            buildInputs = [
              pkgs.libxml2.dev
              pkgs.curl.dev
              pkgs.openssl
              beaker
            ];

            preBuild = ''
              makeFlagsArray+=(
                "PREFIX=$out"
                "CFLAGS=-Wall -Wextra -O2 -Isrc -I${pkgs.libxml2.dev}/include/libxml2"
                "LIBS=-lbeaker -lcurl -lxml2 -lpthread -lm -lssl -lcrypto"
              )
            '';

            installPhase = ''
              mkdir -p $out/bin $out/share/omnisearch
              install -Dm755 bin/omnisearch $out/bin/omnisearch
              cp -r templates static locales -t $out/share/omnisearch/
            '';

            meta = {
              description = "Lightweight metasearch engine in C";
              platforms = pkgs.lib.platforms.linux;
            };
          };
        }
      );
      nixosModules.default = import ./module.nix self;
    };
}
