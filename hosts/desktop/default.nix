# Host: desktop — PC x86_64 com CPU AMD + GPU AMD.
# Greeter SDDM (Wayland) → sessão niri → shell/bar noctalia.
#
# Os módulos `inputs.niri.nixosModules.niri` e
# `inputs.noctalia.nixosModules.default` são injetados pelo flake.nix.
# O hardware real fica em ./hardware-configuration.nix (gere com
# `nixos-generate-config` antes do 1º install).
{ lib, pkgs, inputs, ... }:
{
  networking.hostName = "desktop";

  # Overlay da noctalia → disponibiliza `pkgs.noctalia` (usado como pacote
  # padrão pelo módulo home-manager em home/desktop.nix). O overlay do niri
  # já vem do seu nixosModule.
  nixpkgs.overlays = [ inputs.noctalia.overlays.default ];

  # ── Boot (UEFI + systemd-boot) ────────────────────────────────────
  # Se a placa fizer boot legado/BIOS, troque por GRUB (ver comentário).
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # boot.loader.grub = { enable = true; device = "/dev/sdX"; useOSProber = true; };

  # ── CPU AMD ───────────────────────────────────────────────────────
  hardware.cpu.amd.updateMicrocode = true;

  # ── GPU AMD (amdgpu) ──────────────────────────────────────────────
  # Carrega o driver cedo (KMS) para um boot/greeter limpos.
  boot.initrd.kernelModules = [ "amdgpu" ];
  services.xserver.videoDrivers = [ "amdgpu" ]; # também usado pelo SDDM

  hardware.graphics = {
    enable = true;
    enable32Bit = true; # libs 32-bit (Steam/Wine/jogos)
    # Aceleração de vídeo/compute na AMD. Descomente conforme o uso:
    extraPackages = with pkgs; [
      libva # VA-API
      libva-vdpau-driver # ponte VA-API → VDPAU
      libvdpau-va-gl # ponte VDPAU → VA-API
      # rocmPackages.clr.icd  # OpenCL (ROCm) — só se precisar de compute
    ];
  };
  # Variável que faz apps usarem VA-API via radeonsi.
  environment.sessionVariables.LIBVA_DRIVER_NAME = "radeonsi";

  # ── Rede ──────────────────────────────────────────────────────────
  networking.networkmanager.enable = true;
  users.users.lin.extraGroups = [ "networkmanager" "video" "audio" ];

  # ── Áudio (PipeWire) ──────────────────────────────────────────────
  security.rtkit.enable = true;
  services.pulseaudio.enable = false; # PipeWire substitui o PulseAudio
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # ── Greeter: SDDM em modo Wayland ─────────────────────────────────
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };
  # A sessão "niri" é registrada por programs.niri.enable abaixo.
  services.displayManager.defaultSession = "niri";

  # ── Compositor: niri ──────────────────────────────────────────────
  # Instala o niri, registra a sessão (.desktop) p/ o SDDM e configura
  # polkit/portals básicos. A config do usuário fica em home/desktop.nix.
  programs.niri.enable = true;
  niri-flake.cache.enable = true; # cache binário (niri.cachix.org)

  # ── Sessão gráfica / serviços de apoio ────────────────────────────
  security.polkit.enable = true;
  services.gnome.gnome-keyring.enable = true; # cofre de segredos p/ apps
  programs.dconf.enable = true; # settings de apps GTK
  # Portais XDG (file picker, screenshare). O niri-flake já habilita o
  # backend gnome; o gtk cobre o seletor de arquivos.
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  # ── Fontes ────────────────────────────────────────────────────────
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      noto-fonts
      noto-fonts-color-emoji
      nerd-fonts.jetbrains-mono # ícones p/ a barra (noctalia/p10k)
      nerd-fonts.symbols-only
    ];
  };

  # ── Teclado / console ─────────────────────────────────────────────
  # Brasileiro ABNT2 por padrão (locale do sistema é pt_BR). Ajuste se
  # usar layout US.
  console.keyMap = "br-abnt2";
  services.xserver.xkb = {
    layout = "br";
    variant = "abnt2";
  };

  # ── Pacotes de sistema do desktop ─────────────────────────────────
  environment.systemPackages = with pkgs; [
    wl-clipboard # clipboard Wayland (wl-copy/wl-paste)
    brightnessctl # controle de brilho (usado pela barra)
    pavucontrol # mixer de áudio GUI
    libnotify # notify-send
  ];

  # stateVersion: defina com a versão do 1º install DESTA máquina e não
  # mude depois (controla compatibilidade de dados stateful).
  system.stateVersion = lib.mkDefault "26.05";

  # Config home-manager do `lin` deste host (importa home/common.nix).
  home-manager.users.lin = import ../../home/desktop.nix;
}
