# Config home-manager do `lin` no desktop (CPU/GPU AMD).
# Herda a base de ./common.nix e adiciona o ambiente gráfico:
#   • niri    → compositor (config declarativa via programs.niri.settings)
#   • noctalia→ shell/bar (autostart por systemd user service)
#   • apps Wayland (terminal foot, firefox, etc.)
#
# Os módulos home-manager do niri/noctalia chegam por `inputs`
# (home-manager.extraSpecialArgs no flake.nix).
{ config, pkgs, inputs, ... }:
{
  imports = [
    ./common.nix
    # OBS.: o homeModule do niri NÃO entra aqui — o nixosModule do niri
    # (em flake.nix) já o injeta, então programs.niri.settings e
    # config.lib.niri.actions já estão disponíveis.
    inputs.noctalia.homeModules.default
  ];

  # ── Apps gráficos (tudo declarativo) ──────────────────────────────
  home.packages = with pkgs; [
    firefox
    fuzzel # launcher (noctalia também tem o seu)
    swaybg # wallpaper de fallback (noctalia também gere wallpaper)
    imv # visualizador de imagens
    mpv # vídeo
    nautilus # gerenciador de arquivos GTK
    xwayland-satellite # roda apps X11 sob o niri (inicie via keybind/needed)
  ];

  # Terminal Wayland nativo, leve.
  programs.foot = {
    enable = true;
    settings = {
      main = {
        font = "JetBrainsMono Nerd Font:size=11";
        pad = "8x8";
      };
      colors.alpha = 0.95;
    };
  };

  # ── niri ──────────────────────────────────────────────────────────
  programs.niri.settings = {
    prefer-no-csd = true;

    input = {
      keyboard.xkb = {
        layout = "us";
        variant = "intl";
      };
      touchpad = {
        tap = true;
        natural-scroll = true;
      };
      focus-follows-mouse.enable = true;
    };

    layout = {
      gaps = 12;
      default-column-width.proportion = 0.5;
      focus-ring = {
        enable = true;
        width = 3;
      };
      border.enable = false;
    };

    # Variáveis úteis dentro da sessão Wayland.
    environment = {
      NIXOS_OZONE_WL = "1"; # Electron/Chromium em modo Wayland
      DISPLAY = ":0"; # apps X11 via xwayland-satellite
    };

    # Mod = Super (tecla logo). Só uso actions confirmadas como existentes
    # nesta revisão do niri-flake (config.lib.niri.actions).
    binds = with config.lib.niri.actions; {
      "Mod+Return".action = spawn "foot";
      "Mod+D".action = spawn "fuzzel";
      "Mod+B".action = spawn "firefox";
      "Mod+E".action = spawn "nautilus";
      "Mod+Q".action = close-window;

      # Foco
      "Mod+Left".action = focus-column-left;
      "Mod+Right".action = focus-column-right;
      "Mod+Down".action = focus-window-down;
      "Mod+Up".action = focus-window-up;
      "Mod+H".action = focus-column-left;
      "Mod+L".action = focus-column-right;
      "Mod+J".action = focus-window-down;
      "Mod+K".action = focus-window-up;

      # Mover janela/coluna
      "Mod+Shift+Left".action = move-column-left;
      "Mod+Shift+Right".action = move-column-right;
      "Mod+Shift+Down".action = move-window-down;
      "Mod+Shift+Up".action = move-window-up;
      "Mod+Shift+H".action = move-column-left;
      "Mod+Shift+L".action = move-column-right;
      "Mod+Shift+J".action = move-window-down;
      "Mod+Shift+K".action = move-window-up;

      # Workspaces (focar por número 1–5; navegar/mover por cima-baixo)
      "Mod+1".action = focus-workspace 1;
      "Mod+2".action = focus-workspace 2;
      "Mod+3".action = focus-workspace 3;
      "Mod+4".action = focus-workspace 4;
      "Mod+5".action = focus-workspace 5;
      "Mod+Page_Down".action = focus-workspace-down;
      "Mod+Page_Up".action = focus-workspace-up;
      "Mod+Shift+Page_Down".action = move-column-to-workspace-down;
      "Mod+Shift+Page_Up".action = move-column-to-workspace-up;

      # Tamanho/layout de coluna
      "Mod+R".action = switch-preset-column-width;
      "Mod+F".action = maximize-column;
      "Mod+Shift+F".action = fullscreen-window;
      "Mod+C".action = center-column;
      "Mod+Minus".action = set-column-width "-10%";
      "Mod+Equal".action = set-column-width "+10%";
      "Mod+Comma".action = consume-or-expel-window-left;
      "Mod+Period".action = consume-or-expel-window-right;

      # Overview / ajuda de atalhos
      "Mod+Tab".action = toggle-overview;
      "Mod+Slash".action = show-hotkey-overlay;

      # Mídia / brilho (spawn-sh = roda via `sh -c`, aceita 1 string)
      "XF86AudioRaiseVolume".action = spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
      "XF86AudioLowerVolume".action = spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
      "XF86AudioMute".action = spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
      "XF86MonBrightnessUp".action = spawn-sh "brightnessctl set 5%+";
      "XF86MonBrightnessDown".action = spawn-sh "brightnessctl set 5%-";
      # Screenshot via IPC do próprio niri (a action `screenshot` não é
      # exposta pelo helper nesta revisão).
      "Print".action = spawn-sh "niri msg action screenshot";

      # Sessão
      "Mod+Shift+E".action = quit; # mostra diálogo de confirmação
    };
  };

  # ── noctalia (shell/bar) ──────────────────────────────────────────
  # systemd.enable cria um user service que inicia a noctalia junto com a
  # sessão gráfica (após o wayland target). Sem settings → usa os padrões;
  # configure pela UI da própria noctalia.
  programs.noctalia = {
    enable = true;
    systemd.enable = true;
  };
}
