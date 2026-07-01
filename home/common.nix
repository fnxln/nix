# Base home-manager do usuário `lin`, compartilhada por TODAS as máquinas.
# Cada host importa este arquivo via ./home/<hostname>.nix e adiciona o que
# for específico daquela máquina.
{ pkgs, ... }:
{
  imports = [
    ./shell.nix # zsh + p10k + fzf + carapace + bat + aliases
    ./terminal.nix # zellij
    ./neovim.nix # nixvim (Neovim 100% declarativo)
  ];

  home.username = "lin";
  home.homeDirectory = "/home/lin";

  # Pacotes do usuário disponíveis em qualquer máquina.
  # (bat é configurado em ./shell.nix)
  home.packages = with pkgs; [
    ripgrep
    fd
    eza
    jq
    fastfetch # info do sistema no terminal
  ];

  # nh: helper do Nix/NixOS (nh os switch, nh clean, etc.).
  # O módulo já instala o pacote, então não precisa em home.packages.
  programs.nh = {
    enable = true;
    flake = "/home/lin/nix"; # usado como padrão em `nh os switch` etc.
  };

  programs.git = {
    enable = true;
    settings.user = {
      name = "Lin Vieira";
      email = "lin@fnxln.com";
    };
  };

  # bash continua disponível como fallback; o shell padrão é o zsh.
  programs.bash.enable = true;

  # Deixa o home-manager se gerenciar.
  programs.home-manager.enable = true;

  # NÃO mude após o primeiro uso (mesma lógica do system.stateVersion).
  home.stateVersion = "26.05";
}
