# chiplang-nix {#chiplang-nix}

Nix flake packaging for [ChipLang](https://codeberg.org/ideumi/chip-go), the `chippy` interpreter, its standard library assets, and related tooling.

## Packages {#chiplang-nix-packages}

This flake exports these package attributes on supported Linux systems:

- `chiplang` - the `chippy` interpreter plus standard library and documentation files
- `chiplang-boxflinger` - the Boxflinger terminal UI library packaged for `CHIP_LIB_PATH`
- `boxflinger` - compatibility alias for `chiplang-boxflinger`
- `chiplang-nvim` - Vim/Neovim runtime files for ChipLang syntax highlighting
- `depthfinder` - the `dfn` terminal file manager
- `default` - alias for `chiplang`

## Quick Start {#chiplang-nix-quick-start}

Run the interpreter without installing it:

```bash
nix run github:deadmade/chiplang-nix
nix run github:deadmade/chiplang-nix -- --version
```

Open a development shell with ChipLang and Go tooling:

```bash
nix develop github:deadmade/chiplang-nix
```

The dev shell provides `chippy`, `dfn`, and Go tooling, and sets:

- `CHIP_LIB_PATH` to the packaged ChipLang standard library plus Boxflinger
- `CHIP_DOC_DIR` to the packaged ChipLang documentation directory

## Use in Your Flake {#chiplang-nix-use-in-your-flake}

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    chiplang-nix.url = "github:deadmade/chiplang-nix";
  };

  outputs = { nixpkgs, chiplang-nix, ... }: {
    devShells.x86_64-linux.default =
      let
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
      in
      pkgs.mkShell {
        buildInputs = [
          chiplang-nix.packages.x86_64-linux.chiplang
          chiplang-nix.packages.x86_64-linux.chiplang-boxflinger
        ];
      };
  };
}
```

## NixOS Module {#chiplang-nix-nixos-module}

Import the module directly from the flake. It defaults to this flake's packaged outputs and does not require the overlay.

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    chiplang-nix.url = "github:deadmade/chiplang-nix";
  };

  outputs = { nixpkgs, chiplang-nix, ... }: {
    nixosConfigurations.host = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        chiplang-nix.nixosModules.default
        {
          programs.chiplang.enable = true;
          programs.chiplang.boxflinger.enable = true;
        }
      ];
    };
  };
}
```

When enabled, the module:

- installs the selected `chiplang` package into `environment.systemPackages`
- sets `CHIP_LIB_PATH` to the ChipLang library path and, optionally, the Boxflinger library path
- sets `CHIP_DOC_DIR` to the selected ChipLang package documentation path

## Overlay {#chiplang-nix-overlay}

The overlay exports:

- `chiplang`
- `chiplang-boxflinger`
- `boxflinger`
- `chiplang-nvim`
- `depthfinder`

## Editor Support {#chiplang-nix-editor-support}

`chiplang-nvim` contains the Vim runtime files at:

- `syntax/chiplang.vim`
- `ftdetect/chiplang.vim`

Use it from your preferred Vim or Neovim Nix configuration by adding the package as a plugin or runtime path entry.

## Validation {#chiplang-nix-validation}

`nix flake check` evaluates all exported outputs and runs explicit smoke checks for:

- `chiplang` interpreter execution
- `chiplang-boxflinger` library installation
- `chiplang-nvim` runtime file layout
- `depthfinder` binary layout
- `nixosModules.default` environment variable wiring
