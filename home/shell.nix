# Shell e ferramentas de linha de comando — tradução declarativa do antigo
# ~/dotfiles/zsh/.zshrc + bat/config. Tudo vem do nixpkgs (sem brew/oh-my-zsh
# clonado/fzf/carapace baixados na mão).
{ pkgs, lib, ... }:
{
  # ── Pacotes de CLI antes geridos por brew/scripts ─────────────────
  home.packages = with pkgs; [
    deno # antes via ~/.deno; agora declarativo
  ];

  # ── bat (antes ~/.config/bat/config) ──────────────────────────────
  programs.bat = {
    enable = true;
    config = {
      theme = "TwoDark";
      style = "numbers,changes,header-filename,grid";
      italic-text = "always";
      paging = "auto";
      map-syntax = [
        "*.kdl:YAML"
        ".zshrc.local:Bourne Again Shell (bash)"
        "*.local:Bourne Again Shell (bash)"
      ];
    };
  };

  # ── fzf (antes clonado em ~/.fzf) ─────────────────────────────────
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  # ── carapace (antes baixado em ~/.local/bin) ──────────────────────
  programs.carapace = {
    enable = true;
    enableZshIntegration = true;
  };

  # ── zsh ───────────────────────────────────────────────────────────
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true; # antes: plugin zsh-autosuggestions
    syntaxHighlighting.enable = true; # antes: zsh-syntax-highlighting (sempre por último)
    enableCompletion = true;

    history = {
      size = 50000;
      save = 50000;
      path = "$HOME/.zsh_history";
      ignoreAllDups = true; # HIST_IGNORE_ALL_DUPS
      share = true; # SHARE_HISTORY
    };

    shellAliases = {
      ll = "ls -lah";
      la = "ls -A";
      gs = "git status";
      gd = "git diff";
      ".." = "cd ..";
      "..." = "cd ../..";
      claude = "claude --dangerously-skip-permissions";
      # bat no lugar do cat (auto-plain em pipe). cat real: \cat ou command cat
      cat = "bat";
      catp = "bat --paging=never";
    };

    sessionVariables = {
      CARAPACE_BRIDGES = "zsh,fish,bash,inshellisense";
      MANPAGER = "sh -c 'col -bx | bat -l man -p'";
      MANROFFOPT = "-c";
    };

    oh-my-zsh = {
      enable = true;
      # plugins built-in do oh-my-zsh (fzf/fzf-tab/autosuggestions/syntax
      # vêm dos módulos nativos acima e da lista `plugins` abaixo).
      plugins = [ "git" "z" "sudo" "extract" ];
      extraConfig = ''
        zstyle ':omz:update' mode auto
      '';
    };

    # Plugins que não têm toggle nativo — vindos do nixpkgs.
    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
      {
        name = "fzf-tab"; # deve carregar após compinit e antes do autosuggestions
        src = pkgs.zsh-fzf-tab;
        file = "share/fzf-tab/fzf-tab.plugin.zsh";
      }
    ];

    initContent = lib.mkMerge [
      # Instant prompt do powerlevel10k — mantém bem no topo.
      (lib.mkOrder 500 ''
        if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
          source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
        fi
      '')

      # Resto da config (após omz/compinit e plugins).
      ''
        # bridge para tools que só trazem completion de bash
        autoload -Uz bashcompinit && bashcompinit

        setopt COMPLETE_IN_WORD ALWAYS_TO_END AUTO_MENU NO_CASE_GLOB
        setopt HIST_REDUCE_BLANKS INC_APPEND_HISTORY

        # fallback: exato -> case/parcial -> fuzzy aproximado (tolerante a typo)
        zstyle ':completion:*' completer _complete _match _approximate
        zstyle ':completion:*:approximate:*' max-errors 1 numeric
        zstyle ':completion:*' matcher-list 'm:{a-zA-Z-_}={A-Za-z_-}' 'r:|=*' 'l:|=* r:|=*'
        zstyle ':completion:*' group-name '''
        zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
        zstyle ':completion:*' verbose yes
        zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
        zstyle ':completion:*' use-cache on
        zstyle ':completion:*' cache-path "$HOME/.cache/zcompcache"
        # fzf-tab: preview do conteúdo no cd, repassa cores
        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color=always $realpath 2>/dev/null'
        zstyle ':fzf-tab:*' use-fzf-default-opts yes

        # config do powerlevel10k (arquivo versionado no flake)
        [[ -f "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"

        # overrides locais por máquina (não versionados)
        [[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
      ''
    ];
  };

  # Config do powerlevel10k (antes ~/.p10k.zsh; agora versionada no flake).
  home.file.".p10k.zsh".source = ./zsh/p10k.zsh;

  # ── PATH ──────────────────────────────────────────────────────────
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/go/bin"
    "$HOME/.opencode/bin" # opencode (externo) — inofensivo se ausente
  ];

  home.sessionVariables.EDITOR = lib.mkDefault "nvim";
}
