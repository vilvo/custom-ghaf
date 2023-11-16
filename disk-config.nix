{
  disko.devices = {
    disk.disk1 = {
      type = "disk";
      #device = "/dev/nvme0n1";
      content = {
        type = "gpt";
        partitions = {
          boot = {
            name = "boot";
            size = "1M";
            type = "EF02";
          };
          esp = {
            size = "500M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "crypted";
              extraOpenArgs = ["--allow-discards"];
              # following pre-defined EXAMPLE key,
              # intentionally shared in version control,
              # is generated with:
              # openssl genrsa -out ./example_secret.key
              # with nixos-anywhere - you must securely
              # transfer the key to /root before running
              # nix run github:numtide/nixos-anywhere ...
              settings.keyFile = "/root/example_secret.key";
              content = {
                type = "lvm_pv";
                vg = "ghaf";
              };
            };
          };
        };
      };
    };
    lvm_vg = {
      ghaf = {
        type = "lvm_vg";
        lvs = {
          rootA = {
            size = "30G";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
              mountOptions = [
                "defaults"
              ];
            };
          };
          rootB = {
            size = "30G";
            content = {
              type = "filesystem";
              format = "ext4";
            };
          };
        };
      };
    };
  };
}
