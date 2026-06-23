# Configuração de sistema compartilhada por TODAS as máquinas.
{ lib, pkgs, inputs, ... }:
{
  # ── Nix / flakes ──────────────────────────────────────────────────
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
    trusted-users = [ "root" "@wheel" ];

    # Cache binário do claude-code-nix (opcional — evita compilar localmente).
    # Descomente para usar o cache público do projeto:
    # extra-substituters = [ "https://claude-code.cachix.org" ];
    # extra-trusted-public-keys = [ "claude-code.cachix.org-1:YeXf2aNu7UTX8Vwrze0za1WEDS+4DuI2kVeWEE4fsRk=" ];
  };

  # Coleta de lixo automática (libera espaço de gerações antigas).
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  # Faz `nixpkgs` (no registry e no NIX_PATH) apontar para o nixpkgs deste
  # flake, então `nix shell nixpkgs#hello` usa a mesma revisão do sistema.
  nix.registry.nixpkgs.flake = inputs.nixpkgs;
  nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];

  # ── Localização ───────────────────────────────────────────────────
  time.timeZone = lib.mkDefault "America/Sao_Paulo";
  i18n.defaultLocale = lib.mkDefault "pt_BR.UTF-8";

  # ── Usuário primário (compartilhado entre as máquinas) ────────────
  # `lin` é o usuário padrão (login automático no WSL) e tem sudo SEM
  # senha pela regra logo abaixo.
  users.users.lin = {
    isNormalUser = true;
    uid = 1000; # herda os arquivos do antigo usuário (uid 1000).
    extraGroups = [ "wheel" ]; # `wheel` => acesso a sudo.
    shell = pkgs.zsh; # shell padrão (config declarativa em home/shell.nix).
    # initialPassword = "changeme"; # defina se quiser fazer login/su como lin.
  };

  # Habilita o zsh no sistema (entra em /etc/shells; necessário p/ login shell).
  programs.zsh.enable = true;

  # sudo sem senha APENAS para o `lin` — o `nixos` continua pedindo senha.
  security.sudo.extraRules = [
    {
      users = [ "lin" ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # A config home-manager do `lin` agora é definida POR HOST, em
  # ./hosts/<nome>/default.nix (home-manager.users.lin = import
  # ../../home/<nome>.nix), pois cada arquivo importa ./home/common.nix.

  # Overlay do claude-code-nix => disponibiliza `pkgs.claude-code`.
  nixpkgs.overlays = [ inputs.claude-code.overlays.default ];

  # ── Pacotes base do sistema ───────────────────────────────────────
  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    curl
    htop
    claude-code
  ];

  programs.git.enable = true;

  # Permite instalar pacotes unfree (ex.: drivers). Ajuste se não quiser.
  nixpkgs.config.allowUnfree = lib.mkDefault true;
}
