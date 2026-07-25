# chippy-nix {#chippy-nix}

Nix flake packaging for [Chippy](https://codeberg.org/ideumi/chippy), the `chippy` interpreter, its standard library assets, and related tooling.

## Packages {#chippy-nix-packages}

This flake exports these package attributes on supported Linux systems:

- `chippy` - the `chippy` interpreter plus standard library and documentation files
- `chippy-boxflinger` - the Boxflinger terminal UI library packaged for `CHIP_LIB_PATH`
- `chippy-nvim` - Vim/Neovim runtime files for Chippy syntax highlighting
- `depthfinder` - the `dfn` terminal file manager
- `dfn-mounter` - the `dfn-mounter` Boxflinger-based TUI disk mounter
- `default` - alias for `chippy`

Compatibility aliases for the pre-rename attribute names are still exported:
`chiplang`, `chiplang-nvim`, `chiplang-boxflinger`, and `boxflinger`.

## Quick Start {#chippy-nix-quick-start}

Run the interpreter without installing it:

```bash
nix run github:deadmade/chippy-nix
nix run github:deadmade/chippy-nix -- --version
```

Open a development shell with Chippy and Go tooling:

```bash
nix develop github:deadmade/chippy-nix
```

The dev shell provides `chippy`, `dfn`, and Go tooling, and sets:

- `CHIP_LIB_PATH` to the packaged Chippy standard library plus Boxflinger
- `CHIP_DOC_DIR` to the packaged Chippy documentation directory

## Use in Your Flake {#chippy-nix-use-in-your-flake}

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    chippy-nix.url = "github:deadmade/chippy-nix";
  };

  outputs = { nixpkgs, chippy-nix, ... }: {
    devShells.x86_64-linux.default =
      let
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
      in
      pkgs.mkShell {
        buildInputs = [
          chippy-nix.packages.x86_64-linux.chippy
          chippy-nix.packages.x86_64-linux.chippy-boxflinger
        ];
      };
  };
}
```

## NixOS Module {#chippy-nix-nixos-module}

Import the module directly from the flake. It defaults to this flake's packaged outputs and does not require the overlay.

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    chippy-nix.url = "github:deadmade/chippy-nix";
  };

  outputs = { nixpkgs, chippy-nix, ... }: {
    nixosConfigurations.host = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        chippy-nix.nixosModules.default
        {
          programs.chippy.enable = true;
          programs.chippy.boxflinger.enable = true;
        }
      ];
    };
  };
}
```

When enabled, the module:

- installs the selected `chippy` package into `environment.systemPackages`
- sets `CHIP_LIB_PATH` to the Chippy library path and, optionally, the Boxflinger library path
- sets `CHIP_DOC_DIR` to the selected Chippy package documentation path

The former `programs.chiplang.*` options still work; they are renamed aliases and
emit a deprecation warning pointing at `programs.chippy.*`.

## Overlay {#chippy-nix-overlay}

The overlay exports:

- `chippy`
- `chippy-boxflinger`
- `chippy-nvim`
- `depthfinder`
- `dfn-mounter`
- `chiplang`, `chiplang-nvim`, `chiplang-boxflinger`, `boxflinger` (compatibility aliases)

## Editor Support {#chippy-nix-editor-support}

`chippy-nvim` contains the Vim runtime files at:

- `syntax/chippy.vim`
- `ftdetect/chippy.vim`

Use it from your preferred Vim or Neovim Nix configuration by adding the package as a plugin or runtime path entry.

## Validation {#chippy-nix-validation}

`nix flake check` evaluates all exported outputs and runs explicit smoke checks for:

- `chippy` interpreter execution
- `chippy-boxflinger` library installation
- `chippy-nvim` runtime file layout
- compatibility aliases resolving to the renamed packages
- `depthfinder` binary layout
- `dfn-mounter` binary layout
- `nixosModules.default` environment variable wiring
- `programs.chiplang.*` renamed options matching `programs.chippy.*`
