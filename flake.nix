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
      #url = "git+file:///home/vilvo/ghaf";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
        jetpack-nixos.follows = "jetpack-nixos";
      };
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
  };

  outputs = {
    self,
    ghaf,
    nixpkgs,
    jetpack-nixos,
    flake-utils,
    agenix,
  }: let
    systems = with flake-utils.lib.system; [
      x86_64-linux
      aarch64-linux
    ];
    mkFlashScript = import (ghaf + "/lib/mk-flash-script");
  in
    # Combine list of attribute sets together
    nixpkgs.lib.foldr nixpkgs.lib.recursiveUpdate {} [
      (flake-utils.lib.eachSystem systems (system: {
        formatter = nixpkgs.legacyPackages.${system}.alejandra;
      }))

      {
        nixosConfigurations.custom-ghaf-nx-debug = ghaf.nixosConfigurations.nvidia-jetson-orin-nx-debug.extendModules {
          modules = [
            ./modules/users/accounts.nix
            {
              boot.growPartition = true;

              ghaf = {
                graphics.weston = {
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
                profiles.graphics.enable = nixpkgs.lib.mkForce false;
                windows-launcher.enable = nixpkgs.lib.mkForce false;
              };
            }
          ];
        };

        packages.aarch64-linux.custom-ghaf-nx-debug = self.nixosConfigurations.custom-ghaf-nx-debug.config.system.build.${self.nixosConfigurations.custom-ghaf-nx-debug.config.formatAttr};

        packages.x86_64-linux.custom-ghaf-nx-debug-flash-script = mkFlashScript {
          inherit nixpkgs jetpack-nixos;
          hostConfiguration = self.nixosConfigurations.custom-ghaf-nx-debug;
          flash-tools-system = flake-utils.lib.system.x86_64-linux;
        };

        nixosConfigurations.custom-ghaf-x1-debug = ghaf.nixosConfigurations.lenovo-x1-carbon-gen11-debug.extendModules {
          modules = [
            ./modules/users/accounts.nix
            agenix.nixosModules.default
            ./modules/debug/usb.nix
            {
              ghaf = {

                virtualization.microvm.netvm = {
                  extraModules = [
                    ./modules/networking/wifi.nix
                  ];
                };

                graphics.demo-apps = {
                  chromium = false;
                  firefox = true;
                  gala-app = false;
                  element-desktop = false;
                  zathura = true;
                };

              };

              age.secrets.secret1.file = ./secrets/secret1.age;
            }
          ];
        };
        packages.x86_64-linux.custom-ghaf-x1-debug = self.nixosConfigurations.custom-ghaf-x1-debug.config.system.build.${self.nixosConfigurations.custom-ghaf-x1-debug.config.formatAttr};

       nixosConfigurations.custom-ghaf-x1-hostonly-debug = ghaf.nixosConfigurations.lenovo-x1-carbon-gen11-debug.extendModules {
          modules = [
            ./modules/users/accounts.nix
            ./modules/debug/usb.nix
            {
              ghaf = {
                graphics = {
                  weston = {
                    enable = false;
                    launchers = [ ];
                  };
                };
                virtualization.microvm.appvm.enable = nixpkgs.lib.mkForce false;
                host.kernel_hardening.enable = nixpkgs.lib.mkForce true;
              };
            }
          ];
        };
        packages.x86_64-linux.custom-ghaf-x1-hostonly-debug = self.nixosConfigurations.custom-ghaf-x1-hostonly-debug.config.system.build.${self.nixosConfigurations.custom-ghaf-x1-hostonly-debug.config.formatAttr};


      }
    ];
}
