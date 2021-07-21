{

  inputs = {
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    naersk = {
      url = "github:nmattia/naersk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils, naersk, fenix }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        fenixArch = fenix.packages.${system};
        rustTargets = fenixArch.targets;

        rustToolchain = fenixArch.latest;
        rustEmbedded = rustTargets.thumbv6m-none-eabi.latest;

        naersk-lib = naersk.lib.${system}.override {
          cargo = rustToolchain.toolchain;
          rustc = rustToolchain.toolchain;
        };

      in {

        defaultPackage = naersk-lib.buildPackage (with pkgs; {
          root = ./.;
          src = ./.;
        });

        defaultApp = utils.mkApp {
          drv = self.defaultPackage."${system}";
        };

        devShell =
        with pkgs; mkShell {
          buildInputs = [
            pre-commit pkgconfig

            cargo-binutils
            gcc-arm-embedded
            openocd telnet

            (fenixArch.combine [
              (rustToolchain.withComponents [
                "llvm-tools-preview" "rustfmt-preview"
                "rustc" "cargo" "rust-std"
              ])
              rustEmbedded.toolchain
            ])

            (writeScriptBin "build-upload" ''
              set -e
              cargo objcopy --bin stm32 --target thumbv6m-none-eabi --release -- -O binary fw.bin
              openocd -f interface/stlink.cfg  -f board/st_nucleo_f0.cfg -c 'program "fw.bin" 0x08000000 reset; exit'
            '')

          ];

          RUST_SRC_PATH = "${rustToolchain.rust-src}/lib/rustlib/src/rust/library/";
        };

      });

}
