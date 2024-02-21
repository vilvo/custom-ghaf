# Copyright 2022-2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  description = "custom-x1-hostonly - Ghaf based configuration";

  nixConfig = {
    substituters = [
      "https://cache.vedenemo.dev"
      "https://cache.ssrcdevops.tii.ae"
      "https://ghaf-dev.cachix.org"
      "https://cache.nixos.org/"
    ];
    extra-trusted-substituters = [
      "https://cache.vedenemo.dev"
      "https://cache.ssrcdevops.tii.ae"
      "https://ghaf-dev.cachix.org"
      "https://cache.nixos.org/"
    ];
    extra-trusted-public-keys = [
      "cache.vedenemo.dev:8NhplARANhClUSWJyLVk4WMyy1Wb4rhmWW2u8AejH9E="
      "cache.ssrcdevops.tii.ae:oOrzj9iCppf+me5/3sN/BxEkp5SaFkHfKTPPZ97xXQk="
      "ghaf-dev.cachix.org-1:S3M8x3no8LFQPBfHw1jl6nmP8A7cVWKntoMKN3IsEQY="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ghaf = {
      url = "github:tiiuae/ghaf";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
        nixos-hardware.follows = "nixos-hardware";
      };
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    ghaf,
    disko,
    nixpkgs,
    # deadnix: skip
    nixos-hardware,
    nixos-generators,
    flake-utils,
  }: let
    systems = with flake-utils.lib.system; [
      x86_64-linux
    ];
  in
    # Combine list of attribute sets together
    nixpkgs.lib.foldr nixpkgs.lib.recursiveUpdate {} [
      (flake-utils.lib.eachSystem systems (system: {
        formatter = nixpkgs.legacyPackages.${system}.alejandra;
      }))

      {
        nixosConfigurations.custom-x1-hostonly-ghaf-debug = ghaf.nixosConfigurations.generic-x86_64-debug.extendModules {
          modules = [
            disko.nixosModules.disko
            ./disk-config.nix
            # deadnix: skip
            ({lib, ...}: {
              ghaf = {
                graphics = {
                  weston = {
                    enable = nixpkgs.lib.mkForce false;
                  };
                  labwc = {
                    enable = nixpkgs.lib.mkForce false;
                  };
                };
              };
              # disko.devices.disk.disk1.device = lib.mkDefault "DRIVE_PATH";
            })
          ];
        };
        packages.x86_64-linux.custom-x1-hostonly-ghaf-debug = let
          hostConfiguration = self.nixosConfigurations.custom-x1-hostonly-ghaf-debug;
          formatModule = nixos-generators.nixosModules.raw-efi;
          inherit ((hostConfiguration.extendModules {modules = [formatModule];})) config;
        in
          config.system.build.${config.formatAttr};
      }
    ];
}
