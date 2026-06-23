# Zellij — multiplexador de terminal. Antes via brew + symlink do dotfiles.
# O config.kdl é mantido verbatim (versionado no flake) por ter keybinds e
# plugin (room) que não mapeiam bem para o gerador de settings do módulo.
{ pkgs, ... }:
{
  home.packages = [ pkgs.zellij ];

  # config + layouts declarativos (antes ~/.config/zellij/…).
  # OBS: o `copy_command "clip.exe"` no config.kdl é específico do WSL;
  # num desktop, troque por wl-copy/xclip.
  xdg.configFile = {
    "zellij/config.kdl".source = ./zellij/config.kdl;
    "zellij/layouts/dev.kdl".source = ./zellij/layouts/dev.kdl;
  };
}
