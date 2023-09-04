{
  config = {
    # For WLAN firmwares
    hardware.enableRedistributableFirmware = true;
    networking.wireless = {
      enable = true;
      # set "SSID" and "PASSWORD" to match your wifi
      # TODO: study sops-nix - https://github.com/Mic92/sops-nix
      networks."SSID".psk = "PASSWORD";
    };
  };
}
