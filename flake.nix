# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  description = "dogfood - a Ghaf based example configuration";

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
    jetpack-nixos = {
      url = "github:anduril/jetpack-nixos";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ghaf = {
      url = "github:tiiuae/ghaf";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
        jetpack-nixos.follows = "jetpack-nixos";
      };
    };
  };

  outputs = {
    self,
    ghaf,
    nixpkgs,
    jetpack-nixos,
    flake-utils,
  }: let
    systems = with flake-utils.lib.system; [
      x86_64-linux
      aarch64-linux
    ];
    mkFlashScript = import (ghaf + "/lib/mk-flash-script.nix");
  in
    # Combine list of attribute sets together
    nixpkgs.lib.foldr nixpkgs.lib.recursiveUpdate {} [
      (flake-utils.lib.eachSystem systems (system: {
        formatter = nixpkgs.legacyPackages.${system}.alejandra;
      }))

      {
        nixosConfigurations.dogfood-ghaf-debug = ghaf.nixosConfigurations.nvidia-jetson-orin-agx-debug.extendModules {
          modules = [
            {
              users.users."vilvo"= {
                isNormalUser = true;
                extraGroups = [ "wheel" ];
                openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDdNDuKwAsAff4iFRfujo77W4cyAbfQHjHP57h/7tJde ville.ilvonen@unikie.com" ];
              };
              nix.settings.trusted-users = [ "root" "vilvo" ]; # to test ghaf as remote builder (aarch64) on NVIDIA Orin AGX

              ghaf.graphics.weston = {
                # use nixpkgs.libmkForce to force the priority of conflicting values from ghaf applications.nix and this file
                #
                # error: The option `ghaf.graphics.weston.enable' has conflicting definition values:
                #       - In `/nix/store/10hjscs2lqhg66v5845jh00sg12nsq76-source/modules/profiles/applications.nix': true
                #       - In `<unknown-file>': false
                #       Use `lib.mkForce value` or `lib.mkDefault value` to change the priority on any of these definitions.
                # (use '--show-trace' to show detailed location information)
                enable = nixpkgs.lib.mkForce false;
                enableDemoApplications = nixpkgs.lib.mkForce false;
              };
            }
          ];
        };
        packages.aarch64-linux.dogfood-ghaf-debug = self.nixosConfigurations.dogfood-ghaf-debug.config.system.build.${self.nixosConfigurations.dogfood-ghaf-debug.config.formatAttr};

        packages.x86_64-linux.dogfood-ghaf-debug-flash-script = mkFlashScript {
          inherit nixpkgs jetpack-nixos;
          hostConfiguration = self.nixosConfigurations.dogfood-ghaf-debug;
          flash-tools-system = flake-utils.lib.system.x86_64-linux;
        };
      }
    ];
}
