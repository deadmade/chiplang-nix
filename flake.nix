{
  description = "Chippy - A simple, modular scripting language";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    chippy-src = {
      url = "git+https://codeberg.org/ideumi/chippy?ref=refs/tags/V-1.1.1";
      flake = false;
    };
    boxflinger = {
      url = "git+https://codeberg.org/ideumi/boxflinger?ref=refs/tags/V-1.0.11";
      flake = false;
    };
    depthfinder-src = {
      url = "git+https://codeberg.org/ideumi/depthfinder?ref=refs/tags/V-1.0.14";
      flake = false;
    };
    dfn-mounter-src = {
      url = "git+https://codeberg.org/ideumi/dfn-mounter?ref=refs/tags/V-1.0.4";
      flake = false;
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      chippy-src,
      boxflinger,
      depthfinder-src,
      dfn-mounter-src,
    }:
    let
      lib = nixpkgs.lib;
      linuxSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forEachLinuxSystem = lib.genAttrs linuxSystems;

      versions = {
        chippy = "1.1.1";
        boxflinger = "1.0.11";
        depthfinder = "1.0.14";
        dfn-mounter = "1.0.4";
      };

      makePackages =
        pkgs:
        import ./pkgs {
          inherit pkgs versions;
          chippySrc = chippy-src;
          boxflingerSrc = boxflinger;
          depthfinderSrc = depthfinder-src;
          dfnMounterSrc = dfn-mounter-src;
        };
    in
    {
      packages = forEachLinuxSystem (system: makePackages nixpkgs.legacyPackages.${system});

      devShells = forEachLinuxSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          packages = self.packages.${system};
        in
        {
          default = pkgs.mkShell {
            name = "chippy-dev";

            buildInputs = with pkgs; [
              go
              gopls
              packages.chippy
              packages.chippy-boxflinger
              packages.depthfinder
              packages.dfn-mounter
            ];

            shellHook = ''
              echo "Chippy development environment v${versions.chippy}"
              echo "  Chippy: ${packages.chippy}/bin/chippy"
              echo "  Libraries: ${packages.chippy}/lib/chippy"
              echo "  Documentation: ${packages.chippy}/share/doc/chippy"

              export CHIP_LIB_PATH="${packages.chippy}/lib/chippy:${packages.chippy-boxflinger}/lib/chippy"
              export CHIP_DOC_DIR="${packages.chippy}/share/doc/chippy"
            '';
          };
        }
      );

      checks = forEachLinuxSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          packages = self.packages.${system};
        in
        import ./checks {
          inherit pkgs packages;
          module = self.nixosModules.default;
        }
      );

      nixosModules.default = import ./module.nix self;

      overlays.default =
        final: prev:
        let
          packages = makePackages final;
        in
        {
          inherit (packages)
            chippy
            chippy-nvim
            chippy-boxflinger
            chiplang
            chiplang-nvim
            chiplang-boxflinger
            boxflinger
            depthfinder
            dfn-mounter
            ;
        };
    };
}
