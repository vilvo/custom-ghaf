# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  description = "PROJ_NAME - Ghaf based configuration";

  nixConfig = {
    extra-trusted-substituters = [
      "https://cache.vedenemo.dev"
      "https://cache.ssrcdevops.tii.ae"
    ];
    extra-trusted-public-keys = [
      "cache.vedenemo.dev:RGHheQnb6rXGK5v9gexJZ8iWTPX6OcSeS56YeXYzOcg="
      "cache.ssrcdevops.tii.ae:oOrzj9iCppf+me5/3sN/BxEkp5SaFkHfKTPPZ97xXQk="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
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
    nixos-generators,
    nixos-hardware,
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
        nixosConfigurations.PROJ_NAME-ghaf-debug = ghaf.nixosConfigurations.generic-x86_64-debug.extendModules {
          modules = [
            disko.nixosModules.disko
            ./disk-config.nix
            {
              #insert your additional modules here e.g.
              # virtualisation.docker.enable = true;
              # users.users."ghaf".extraGroups = ["docker"];

              # To handle the majority of laptops we need a little something extra
              # TODO:: SEE: https://github.com/NixOS/nixos-hardware/blob/master/flake.nix
              # nixos-hardware.nixosModules.lenovo-thinkpad-x1-10th-gen

              # Required for successful installation via nixos-anywhere
              boot.loader.grub = {
                # no need to set devices, disko will add all devices that have a EF02 partition to the list already
                # devices = [ ];
                efiSupport = true;
                efiInstallAsRemovable = true;
              };

              # Write public ssh keys that will be used to install the system.
              # ghaf.installer.sshKeys = [
              #   "ssh-rsa AAAAB3NzaC1yc2etc/etc/etcjwrsh8e596z6J0l7 example@host"
              #   "ssh-ed25519 AAAAC3NzaCetcetera/etceteraJZMfk3QPfQ foo@bar"
              # ];

              # Insert block device on which system will be installed (this will destory all content on it).
              # disko.devices.disk.disk1.device = "/dev/nvme0n1";
            }
          ];
        };
        packages.x86_64-linux.PROJ_NAME-ghaf-debug = let
          hostConfiguration = self.nixosConfigurations.PROJ_NAME-ghaf-debug;
          formatModule = nixos-generators.nixosModules.raw-efi;
          config = (hostConfiguration.extendModules {modules = [formatModule];}).config;
        in
          config.system.build.${config.formatAttr};
      }
    ];
}
