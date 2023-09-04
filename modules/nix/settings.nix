{
  config = {
    nix.settings.trusted-users = [ "root" "vilvo" ]; # to test ghaf as remote builder (aarch64) on NVIDIA Orin AGX
  };
}
