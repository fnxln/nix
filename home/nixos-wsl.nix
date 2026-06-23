# Config home-manager do `lin` específica da máquina WSL.
# Herda tudo de ./common.nix e adiciona só o que faz sentido sob o WSL.
{ pkgs, ... }:
{
  imports = [ ./common.nix ];

  # ── Específico do WSL ─────────────────────────────────────────────
  # `wslu` foi descontinuado/removido do nixpkgs, então definimos um shim
  # `wslview` próprio que abre URLs/arquivos no app padrão do Windows via
  # interop (cmd.exe). Requer o mount padrão do NixOS-WSL em /mnt/c.
  home.packages = [
    (pkgs.writeShellScriptBin "wslview" ''
      exec /mnt/c/Windows/System32/cmd.exe /c start "" "$@"
    '')
  ];

  # Faz CLIs (git, gh, xdg-open…) abrirem links no navegador do Windows.
  home.sessionVariables.BROWSER = "wslview";
}
