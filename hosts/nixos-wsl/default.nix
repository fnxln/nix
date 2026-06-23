# Host: nixos-wsl — NixOS rodando sob WSL2.
# O módulo do NixOS-WSL é injetado pelo flake
# (inputs.nixos-wsl.nixosModules.default), então aqui ficam só as opções
# específicas desta máquina.
{ ... }:
{
  networking.hostName = "nixos-wsl";

  # Config home-manager do `lin` específica deste host (herda home/common.nix).
  home-manager.users.lin = import ../../home/nixos-wsl.nix;

  # ── Opções específicas do WSL ─────────────────────────────────────
  wsl.enable = true;
  wsl.defaultUser = "lin"; # usuário com login automático no WSL
  # wsl.interop.includePath = true;        # adiciona o PATH do Windows
  # wsl.startMenuLaunchers = true;          # atalhos no menu iniciar do Windows
  # wsl.wslConf.network.hostname = "nixos-wsl"; # alinha o hostname do WSL

  # stateVersion: mantenha no valor do primeiro install desta máquina.
  # NÃO mude ao atualizar — controla compatibilidade de dados stateful.
  system.stateVersion = "26.05";
}
