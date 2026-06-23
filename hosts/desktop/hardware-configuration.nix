# ⚠️  PLACEHOLDER — NÃO é o hardware real desta máquina.
#
# Este arquivo existe só para o flake AVALIAR/CONSTRUIR antes da instalação.
# Os valores (UUIDs de disco, sistema de arquivos, swap, módulos de kernel)
# são fictícios e NÃO vão dar boot na máquina real.
#
# Na máquina nova, durante o install, SUBSTITUA este arquivo inteiro por:
#
#     nixos-generate-config --show-hardware-config \
#       > /home/lin/nix/hosts/desktop/hardware-configuration.nix
#
# (ou copie de /etc/nixos/hardware-configuration.nix após o generate).
{ lib, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # Módulos típicos de uma placa AMD x86_64 (o generate ajusta conforme o HW).
  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  boot.kernelModules = [ "kvm-amd" ];

  # Raiz e /boot fictícios — troque pelos UUIDs reais do generate.
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/BOOT";
    fsType = "vfat";
  };
  # swapDevices = [ { device = "/dev/disk/by-label/swap"; } ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.enableRedistributableFirmware = lib.mkDefault true;
}
