# chiplang-nix

Nix flake for [ChipLang](https://codeberg.org/ideumi/chip-go) - A simple, modular scripting language.

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

### Development Shell

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
