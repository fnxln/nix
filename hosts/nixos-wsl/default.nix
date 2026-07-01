# Host: nixos-wsl — NixOS rodando sob WSL2.
# O módulo do NixOS-WSL é injetado pelo flake
# (inputs.nixos-wsl.nixosModules.default), então aqui ficam só as opções
# específicas desta máquina.
{ pkgs, ... }:
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

  # Corrige o VS Code Remote server sob NixOS (módulo K900/vscode-remote-workaround,
  # importado pelo flake). Opção é top-level, não sob `wsl.`.
  # O default do módulo é `nodejs-18_x`, que já não existe no nixpkgs unstable;
  # aponta para o nodejs_22 (versão que o VS Code server atual empacota).
  vscode-remote-workaround.enable = true;
  vscode-remote-workaround.package = pkgs.nodejs_22;

  # stateVersion: mantenha no valor do primeiro install desta máquina.
  # NÃO mude ao atualizar — controla compatibilidade de dados stateful.
  system.stateVersion = "26.05";
}
