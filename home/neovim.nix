# Neovim 100% declarativo via nixvim, substituindo o antigo setup LazyVim.
#
# Filosofia: replicar a experiência curada do LazyVim (mesmos plugins/LSPs/
# formatters), mas tudo gerenciado pelo Nix — sem mason, sem lazy.nvim.
# Os arquivos options/keymaps/autocmds do LazyVim antigo estavam vazios,
# então só portamos: extras de linguagem, colorscheme, plugins rtp
# desabilitados e o plugin custom do Claude Code.
{
  pkgs,
  inputs,
  lib,
  ...
}:
{
  # Módulo home-manager do nixvim. No nixvim atual o atributo é `homeModules`
  # (o antigo `homeManagerModules` foi renomeado).
  imports = [ inputs.nixvim.homeModules.nixvim ];

  programs.nixvim = {
    enable = true;

    # Usa o mesmo nixpkgs do flake (já garantido pelo `follows`); definir a
    # source explicitamente silencia o aviso de divergência do nixvim.
    nixpkgs.source = inputs.nixpkgs;

    # Carrega o nixvim como editor padrão (substitui o `nvim` do sistema).
    viAlias = true;
    vimAlias = true;

    # ── Opções base (equivalentes aos defaults do LazyVim) ───────────────
    globals = {
      mapleader = " ";
      maplocalleader = "\\";
    };

    opts = {
      number = true; # numeração de linhas
      relativenumber = true; # numeração relativa (movimento rápido)
      shiftwidth = 2; # indentação de 2 espaços
      tabstop = 2;
      expandtab = true; # tabs viram espaços
      smartindent = true;
      wrap = false; # sem quebra de linha visual
      ignorecase = true; # busca case-insensitive…
      smartcase = true; # …a menos que haja maiúsculas
      termguicolors = true; # cores 24-bit (necessário p/ tokyonight)
      signcolumn = "yes"; # coluna de sinais sempre visível
      cursorline = true;
      scrolloff = 4; # margem de rolagem
      undofile = true; # histórico de undo persistente
      timeoutlen = 300; # responsividade do which-key
      updatetime = 200;
      splitright = true; # splits novos à direita…
      splitbelow = true; # …e abaixo
      completeopt = [
        "menu"
        "menuone"
        "noselect"
      ];
    };

    # Plugins internos do Neovim desabilitados no rtp (como em LazyVim/lazy.lua).
    extraConfigLuaPre = ''
      vim.g.loaded_gzip = 1
      vim.g.loaded_tarPlugin = 1
      vim.g.loaded_tar = 1
      vim.g.loaded_2html_plugin = 1
      vim.g.loaded_tutor_mode_plugin = 1
      vim.g.loaded_zipPlugin = 1
      vim.g.loaded_zip = 1
    '';

    # ── Colorscheme: tokyonight (default do LazyVim), fallback habamax ────
    colorschemes.tokyonight = {
      enable = true;
      settings.style = "moon";
    };

    # ── Treesitter: grammars relevantes às linguagens habilitadas ────────
    plugins.treesitter = {
      enable = true;
      settings = {
        highlight.enable = true;
        indent.enable = true;
        ensure_installed = [
          "lua"
          "vim"
          "vimdoc"
          "nix"
          "go"
          "gomod"
          "gowork"
          "gosum"
          "rust"
          "dockerfile"
          "json"
          "jsonc"
          "yaml"
          "toml"
          "markdown"
          "markdown_inline"
          "bash"
          "git_config"
          "gitcommit"
          "gitignore"
          "git_rebase"
          "diff"
          "ini"
          "regex"
        ];
      };
    };

    # ── LSP: servidores gerenciados via Nix (nixvim puxa os binários) ────
    plugins.lsp = {
      enable = true;
      servers = {
        lua_ls.enable = true; # Lua
        nixd.enable = true; # Nix (nixd, mais completo que nil)
        gopls.enable = true; # Go
        dockerls.enable = true; # Dockerfile
        docker_compose_language_service.enable = true; # docker-compose
        jsonls.enable = true; # JSON
        taplo.enable = true; # TOML
        marksman.enable = true; # Markdown
        bashls.enable = true; # Bash
        yamlls.enable = true; # YAML
        # Rust NÃO entra aqui: é gerenciado pelo rustaceanvim (abaixo),
        # que configura o rust-analyzer por conta própria.
      };
      keymaps.lspBuf = {
        "gd" = "definition";
        "gr" = "references";
        "gD" = "declaration";
        "gI" = "implementation";
        "gy" = "type_definition";
        "K" = "hover";
        "<leader>cr" = "rename";
        "<leader>ca" = "code_action";
      };
    };

    # Rust via rustaceanvim (configura rust-analyzer automaticamente).
    plugins.rustaceanvim.enable = true;
    # crates.nvim: gestão de dependências em Cargo.toml.
    plugins.crates.enable = true;

    # ── Completion: blink-cmp (o que o LazyVim atual usa) ────────────────
    plugins.blink-cmp = {
      enable = true;
      settings = {
        keymap.preset = "default";
        appearance.nerd_font_variant = "mono";
        sources.default = [
          "lsp"
          "path"
          "snippets"
          "buffer"
        ];
        completion.documentation.auto_show = true;
        signature.enabled = true;
      };
    };

    # ── Copilot (extra ai.copilot) ───────────────────────────────────────
    # copilot-lua provê o backend; blink-cmp-copilot injeta a fonte no blink.
    plugins.copilot-lua = {
      enable = true;
      settings = {
        suggestion.enabled = false; # sugestões inline desligadas (usamos o blink)
        panel.enabled = false;
      };
    };
    plugins.blink-cmp-copilot.enable = true;

    # ── snacks.nvim (picker/explorer/terminal) — exigido pelo claudecode ─
    plugins.snacks = {
      enable = true;
      settings = {
        bigfile.enabled = true;
        picker.enabled = true;
        explorer.enabled = true;
        terminal.enabled = true;
        notifier.enabled = true;
        quickfile.enabled = true;
        indent.enabled = true;
        scope.enabled = true;
        words.enabled = true;
      };
    };

    # ── Plugins de UX equivalentes ao LazyVim ────────────────────────────
    plugins.which-key.enable = true; # dicas de keymaps
    plugins.gitsigns.enable = true; # sinais de git na gutter
    plugins.lualine.enable = true; # statusline
    plugins.bufferline.enable = true; # abas/buffers
    plugins.neo-tree.enable = true; # árvore de arquivos
    plugins.flash.enable = true; # navegação rápida
    plugins.trouble.enable = true; # lista de diagnósticos
    plugins.todo-comments.enable = true; # destaque de TODO/FIXME
    plugins.nvim-autopairs.enable = true; # fecha parênteses/aspas
    plugins.indent-blankline.enable = true; # guias de indentação
    plugins.web-devicons.enable = true; # ícones (dependência comum)

    # noice + notify (UI de mensagens/cmdline; nui é dependência implícita)
    plugins.noice.enable = true;
    plugins.notify.enable = true;

    # mini.* básicos
    plugins.mini = {
      enable = true;
      modules = {
        ai = { }; # text objects extras
        pairs = { }; # pares (alternativa leve)
        surround = { }; # surround (ys/ds/cs)
        comment = { }; # comentários gc/gcc
      };
    };

    # ── conform.nvim: formatação (formatters via Nix) ────────────────────
    plugins.conform-nvim = {
      enable = true;
      settings = {
        format_on_save = {
          timeout_ms = 1000;
          lsp_format = "fallback";
        };
        formatters_by_ft = {
          lua = [ "stylua" ];
          go = [ "gofumpt" ];
          rust = [ "rustfmt" ];
          nix = [ "nixfmt" ];
          toml = [ "taplo" ];
          json = [ "prettier" ];
          jsonc = [ "prettier" ];
          yaml = [ "prettier" ];
          markdown = [ "prettier" ];
        };
      };
    };

    # ── nvim-lint: linters (binários via Nix) ────────────────────────────
    plugins.lint = {
      enable = true;
      lintersByFt = {
        dockerfile = [ "hadolint" ];
        markdown = [ "markdownlint" ];
      };
    };

    # ── neotest (extra test.core) com adapters go e rust ─────────────────
    plugins.neotest = {
      enable = true;
      adapters.golang.enable = true; # neotest-golang
      adapters.rust.enable = true; # neotest-rust
    };

    # ── Pacotes externos (formatters/linters não puxados automaticamente) ─
    # nixfmt-rfc-style fornece o binário `nixfmt`; prettier, stylua, gofumpt
    # e os linters precisam estar no PATH do nvim.
    extraPackages = with pkgs; [
      stylua
      gofumpt
      nixfmt # nixfmt-rfc-style (agora é o nixfmt padrão)
      prettier
      taplo
      hadolint
      markdownlint-cli
    ];

    # ── Plugin custom: claudecode.nvim (porte fiel do antigo claude.lua) ─
    # claudecode-nvim existe no nixpkgs unstable; snacks já está habilitado
    # acima como provider de terminal.
    extraPlugins = [ pkgs.vimPlugins.claudecode-nvim ];

    # Configuração + autocmd + keymaps do claudecode, replicando o spec Lua.
    # Inclui também o fallback de colorscheme (mkAfter) no fim.
    extraConfigLua = ''
      require("claudecode").setup({
        terminal_cmd = "claude --dangerously-skip-permissions",
        terminal = {
          provider = "snacks",
          split_side = "right",
          split_width_percentage = 0.40,
        },
      })

      -- TermOpen: <Esc><Esc> sai do modo terminal no buffer do Claude.
      vim.api.nvim_create_autocmd("TermOpen", {
        pattern = "term://*claude*",
        callback = function(ev)
          vim.keymap.set("t", "<Esc><Esc>", [[<C-\><C-n>]], { buffer = ev.buf, desc = "Terminal -> normal mode" })
        end,
      })

      -- Picker de sessões por cwd (<leader>aR): lista ~/.claude/projects/<cwd>/*.jsonl,
      -- ordena por mtime desc, extrai preview da 1ª msg de usuário e resume via select.
      local function claude_resume_picker()
        local cwd = vim.fn.getcwd()
        local project_dir = vim.fn.expand("~/.claude/projects/") .. cwd:gsub("[^%w]", "-")
        local files = vim.fn.glob(project_dir .. "/*.jsonl", false, true)
        if #files == 0 then vim.notify("No Claude sessions for " .. cwd, vim.log.levels.WARN); return end
        table.sort(files, function(a, b) return vim.fn.getftime(a) > vim.fn.getftime(b) end)
        local items = {}
        for _, file in ipairs(files) do
          local id = vim.fn.fnamemodify(file, ":t:r")
          local preview, scanned = nil, 0
          for line in io.lines(file) do
            scanned = scanned + 1
            if scanned > 50 then break end
            local ok, entry = pcall(vim.json.decode, line)
            if ok and entry.type == "user" and not entry.isMeta and entry.message then
              local content = entry.message.content
              if type(content) == "table" then
                for _, part in ipairs(content) do if part.type == "text" then content = part.text; break end end
              end
              if type(content) == "string" then preview = content:gsub("%s+", " "):sub(1, 80); break end
            end
          end
          table.insert(items, { id = id, label = os.date("%d/%m %H:%M", vim.fn.getftime(file)) .. "  " .. (preview or id) })
        end
        vim.ui.select(items, { prompt = "Resume Claude session", format_item = function(item) return item.label end },
          function(choice) if choice then vim.cmd("ClaudeCode --resume " .. choice.id) end end)
      end

      -- Keymaps do Claude (grupo <leader>a — "ai/claude").
      local map = vim.keymap.set
      map("n", "<leader>ac", "<cmd>ClaudeCode<cr>", { desc = "Toggle Claude" })
      map("n", "<leader>af", "<cmd>ClaudeCodeFocus<cr>", { desc = "Focus Claude" })
      map("n", "<leader>ar", "<cmd>ClaudeCode --resume<cr>", { desc = "Resume Claude" })
      map("n", "<leader>aR", claude_resume_picker, { desc = "Resume session (cwd picker)" })
      map("n", "<leader>aC", "<cmd>ClaudeCode --continue<cr>", { desc = "Continue Claude" })
      map("n", "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", { desc = "Select Claude model" })
      map("n", "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", { desc = "Add current buffer" })
      map("v", "<leader>as", "<cmd>ClaudeCodeSend<cr>", { desc = "Send selection to Claude" })
      map("n", "<leader>as", "<cmd>ClaudeCodeTreeAdd<cr>", { desc = "Add file from tree" })
      map("n", "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", { desc = "Accept diff" })
      map("n", "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", { desc = "Deny diff" })

      -- Fallback de colorscheme caso o tokyonight falhe por algum motivo.
      pcall(function()
        if vim.g.colors_name == nil then vim.cmd.colorscheme("habamax") end
      end)
    '';

    # ── Keymaps gerais (cobertura dos atalhos comuns do LazyVim) ─────────
    keymaps = [
      # janelas
      {
        mode = "n";
        key = "<C-h>";
        action = "<C-w>h";
        options.desc = "Ir para janela à esquerda";
      }
      {
        mode = "n";
        key = "<C-j>";
        action = "<C-w>j";
        options.desc = "Ir para janela abaixo";
      }
      {
        mode = "n";
        key = "<C-k>";
        action = "<C-w>k";
        options.desc = "Ir para janela acima";
      }
      {
        mode = "n";
        key = "<C-l>";
        action = "<C-w>l";
        options.desc = "Ir para janela à direita";
      }
      # explorer / arquivos
      {
        mode = "n";
        key = "<leader>e";
        action = "<cmd>Neotree toggle<cr>";
        options.desc = "Explorer (Neo-tree)";
      }
      # picker (snacks)
      {
        mode = "n";
        key = "<leader>ff";
        action = "<cmd>lua Snacks.picker.files()<cr>";
        options.desc = "Buscar arquivos";
      }
      {
        mode = "n";
        key = "<leader>fg";
        action = "<cmd>lua Snacks.picker.grep()<cr>";
        options.desc = "Grep no projeto";
      }
      {
        mode = "n";
        key = "<leader>fb";
        action = "<cmd>lua Snacks.picker.buffers()<cr>";
        options.desc = "Buscar buffers";
      }
      # buffers
      {
        mode = "n";
        key = "<S-h>";
        action = "<cmd>bprevious<cr>";
        options.desc = "Buffer anterior";
      }
      {
        mode = "n";
        key = "<S-l>";
        action = "<cmd>bnext<cr>";
        options.desc = "Próximo buffer";
      }
      {
        mode = "n";
        key = "<leader>bd";
        action = "<cmd>bdelete<cr>";
        options.desc = "Fechar buffer";
      }
      # diagnósticos / trouble
      {
        mode = "n";
        key = "<leader>xx";
        action = "<cmd>Trouble diagnostics toggle<cr>";
        options.desc = "Diagnósticos (Trouble)";
      }
      # formatação manual
      {
        mode = "n";
        key = "<leader>cf";
        action = "<cmd>lua require('conform').format({ async = true })<cr>";
        options.desc = "Formatar buffer";
      }
      # testes (neotest)
      {
        mode = "n";
        key = "<leader>tt";
        action = "<cmd>lua require('neotest').run.run()<cr>";
        options.desc = "Rodar teste mais próximo";
      }
      {
        mode = "n";
        key = "<leader>tf";
        action = "<cmd>lua require('neotest').run.run(vim.fn.expand('%'))<cr>";
        options.desc = "Rodar testes do arquivo";
      }
      {
        mode = "n";
        key = "<leader>ts";
        action = "<cmd>lua require('neotest').summary.toggle()<cr>";
        options.desc = "Resumo de testes";
      }
      # salvar / limpar busca
      {
        mode = "n";
        key = "<leader>w";
        action = "<cmd>w<cr>";
        options.desc = "Salvar arquivo";
      }
      {
        mode = "n";
        key = "<Esc>";
        action = "<cmd>nohlsearch<cr>";
        options.desc = "Limpar destaque de busca";
      }
    ];
  };
}
