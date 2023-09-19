{
  boot.kernelParams = [
    "earlyprintk=xkdc,keep"
  ];

  boot.kernelPatches = [
    {
      name = "USB debug port";
      patch = null;
      extraConfig = ''
        USB_XHCI_DBGCAP y
        EARLY_PRINTK_USB_XDBC y
      '';
    }
  ];
}
