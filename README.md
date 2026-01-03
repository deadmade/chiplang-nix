# chiplang-nix

Nix flake for [ChipLang](https://codeberg.org/ideumi/chip-go) - A simple, modular scripting language.

## Packages

This flake provides:
- `chiplang` - The ChipLang interpreter (`chippy` binary) with standard library and documentation
- `chiplang-nvim` - Neovim/Vim plugin for ChipLang syntax highlighting

## Quick Start

### Try Without Installing

```bash
# Run the REPL
nix run github:deadmade/chiplang-nix

# Run a one-liner
nix run github:deadmade/chiplang-nix -- -r 'fwrite(pack("Hello from ChipLang!") + b[10], 1);'

# Check version
nix run github:deadmade/chiplang-nix -- --version
```

### Install to Your Profile

## Usage

### NixOS System Configuration

Add to your `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    chiplang-nix.url = "github:deadmade/chiplang-nix";
  };

  outputs = { self, nixpkgs, chiplang-nix }: {
    nixosConfigurations.yourhostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        chiplang-nix.nixosModules.default
        {
          programs.chiplang.enable = true;
        }
        # ... your other configuration
      ];
    };
  };
}
```

### Development Shell for ChipLang Development

For working on ChipLang itself, use the provided development shell:

```bash
cd chip-go
nix develop ./chiplang-nix
```

This provides:
- Go toolchain with `gopls` LSP
- Pre-built ChipLang binary (`chippy`)
- ChipLang standard library (`CHIP_LIB_PATH`)
- ChipLang documentation (`CHIP_DOC_DIR`)
- **Automatic Neovim syntax highlighting** for `.chp` and `.chh` files

The devShell sets `NVIM_EXTRA_RUNTIME` to enable ChipLang syntax highlighting in Neovim automatically when you open `.chp` or `.chh` files.

### Development Shell for Your ChipLang Projects

Add to your project's `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    chiplang-nix.url = "github:deadmade/chiplang-nix";
  };

  outputs = { self, nixpkgs, chiplang-nix }: {
    devShells.x86_64-linux.default = 
      let
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
      in
      pkgs.mkShell {
        buildInputs = [
          chiplang-nix.packages.x86_64-linux.default
        ];
      };
  };
}
```

### Neovim Integration

The flake provides a `chiplang-nvim` package for syntax highlighting in Neovim/Vim.

#### Option 1: Automatic (via devShell)
When using `nix develop ./chiplang-nix` in the chip-go repository, Neovim will automatically detect ChipLang syntax - no configuration needed!

#### Option 2: Manual Installation (Nixvim/Home Manager)
Add to your Neovim configuration:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    chiplang-nix.url = "github:deadmade/chiplang-nix";
    nixvim.url = "github:nix-community/nixvim";
  };

  outputs = { nixvim, chiplang-nix, ... }: {
    programs.neovim = {
      enable = true;
      plugins = [ chiplang-nix.packages.x86_64-linux.chiplang-nvim ];
    };
  };
}
```

The plugin provides:
- Syntax highlighting for `.chp` (ChipLang scripts) and `.chh` (ChipLang headers)
- Keyword recognition (var, func, return, if, for, while, etc.)
- Built-in function highlighting
- String and number highlighting
- Comment support with TODO/FIXME/NOTE markers
