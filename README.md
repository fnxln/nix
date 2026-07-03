# nix — configurações NixOS multi-host

Flake único para gerenciar várias máquinas NixOS. Usa **nixos-unstable** e
integra **home-manager**. A primeira máquina é a `nixos-wsl` (NixOS sob WSL2).

## Estrutura

```
.
├── flake.nix                 # inputs + helper mkHost + nixosConfigurations
├── hosts/
│   ├── nixos-wsl/
│   │   └── default.nix       # opções específicas desta máquina (WSL, hostname)
│   └── desktop/
│       ├── default.nix       # PC AMD: SDDM + niri + noctalia, áudio, rede…
│       └── hardware-configuration.nix  # PLACEHOLDER — gere com nixos-generate-config
├── modules/
│   └── nixos/
│       ├── default.nix       # agrega os módulos comuns
│       └── common.nix        # config compartilhada (nix/flakes, locale, usuário…)
└── home/
    ├── common.nix            # base home-manager do `lin` (importa os módulos abaixo)
    ├── nixos-wsl.nix         # home do `lin` no WSL (wslview etc.; importa common.nix)
    ├── desktop.nix           # home do `lin` no desktop: niri (binds) + noctalia + apps
    ├── shell.nix             # zsh + powerlevel10k + fzf + carapace + bat + aliases
    ├── terminal.nix          # zellij (config.kdl + layouts)
    ├── neovim.nix            # nixvim — Neovim 100% declarativo (config + plugins)
    ├── zsh/p10k.zsh          # config do powerlevel10k (sourçada pelo shell.nix)
    └── zellij/               # config.kdl + layouts/ implantados pelo terminal.nix
```

> **Dotfiles convertidos:** o antigo `~/dotfiles` (symlinks + `install.sh` com
> brew/oh-my-zsh/fzf/carapace baixados na mão) virou config declarativa nos
> módulos `home/shell.nix`, `home/terminal.nix` e `home/neovim.nix`. Tudo vem do
> nixpkgs; nada é baixado em runtime (exceto plugins resolvidos pelo nixvim no
> build). O shell padrão do `lin` agora é o zsh.

- **`modules/nixos/common.nix`** vale para todos os hosts.
- **`hosts/<nome>/default.nix`** é só daquela máquina e escolhe qual config de
  home usar: `home-manager.users.lin = import ../../home/<nome>.nix;`.
- **`home/common.nix`** é a base de usuário compartilhada; cada **`home/<nome>.nix`**
  a importa e adiciona o que for específico daquele host.

## Inputs

| input          | origem                                   | observação                     |
| -------------- | ---------------------------------------- | ------------------------------ |
| `nixpkgs`      | `github:NixOS/nixpkgs/nixos-unstable`    | canal unstable                 |
| `nixos-wsl`    | `github:nix-community/NixOS-WSL/main`    | branch que acompanha o unstable|
| `home-manager` | `github:nix-community/home-manager`      | `follows` o mesmo `nixpkgs`    |
| `claude-code`  | `github:sadjow/claude-code-nix`          | overlay → `pkgs.claude-code`   |
| `nixvim`       | `github:nix-community/nixvim`             | Neovim declarativo (home/neovim.nix) |
| `niri`         | `github:sodiboo/niri-flake`              | compositor Wayland (host `desktop`)  |
| `noctalia`     | `github:noctalia-dev/noctalia-shell`     | shell/bar Wayland (host `desktop`)   |

> O `claude-code` é instalado via overlay em `modules/nixos/common.nix`
> (`environment.systemPackages`). Há um cache binário opcional comentado em
> `nix.settings` para evitar compilar localmente.

## Aplicar nesta máquina (nixos-wsl)

Esta máquina ainda está em *channels* (26.05). Como os flakes **ainda não estão
habilitados** no sistema, na **primeira vez** passe a feature na linha de comando:

```bash
sudo nixos-rebuild switch \
  --flake /home/lin/nix#nixos-wsl \
  --option experimental-features 'nix-command flakes'
```

Isso migra o sistema para o unstable e ativa flakes de forma permanente (via
`nix.settings.experimental-features`). **Nas próximas vezes** basta:

```bash
sudo nixos-rebuild switch --flake /home/lin/nix#nixos-wsl
```

> Dica: para testar sem ativar de vez, troque `switch` por `build` (não aplica)
> ou `test` (aplica até o próximo boot).

## Instalar o host `desktop` (PC x86_64 AMD)

Máquina nova com **CPU AMD + GPU AMD**, greeter **SDDM** (Wayland), compositor
**niri** e shell/bar **noctalia** — tudo o que dá é declarativo via home-manager.

👉 **Guia completo de instalação (fresh install pelo ISO):**
[`docs/instalar-desktop.md`](docs/instalar-desktop.md) — particionar, clonar o
flake, regerar o hardware, **definir a senha do `lin`** e `nixos-install`.

Notas:
- O cache binário do niri (`niri.cachix.org`) é habilitado por
  `niri-flake.cache.enable`, evitando compilar o compositor.
- O módulo NixOS do niri já injeta o módulo home-manager
  (`programs.niri.settings`), por isso `home/desktop.nix` **não** importa o
  homeModule do niri de novo (senão dá opção declarada em duplicidade).
- A config da noctalia é por padrão a da própria UI; para fixá-la no Nix, use
  `programs.noctalia.settings` (atrset → `~/.config/noctalia/config.toml`).

## Atualizar (bump dos inputs)

```bash
# atualiza tudo e regrava o flake.lock
nix flake update --flake /home/lin/nix

# ou só um input
nix flake update nixpkgs --flake /home/lin/nix
```

Depois rode o `nixos-rebuild switch` de novo.

## Adicionar um novo PC

1. Gere o hardware do novo host (na máquina nova):
   `nixos-generate-config --show-hardware-config > hosts/<nome>/hardware-configuration.nix`
2. Crie `hosts/<nome>/default.nix` com as opções da máquina e aponte o home:
   `home-manager.users.lin = import ../../home/<nome>.nix;`.
3. Crie `home/<nome>.nix` (importando `./common.nix`) com os ajustes de usuário
   daquele host — use `home/desktop.nix` como modelo.
4. Descomente o bloco de exemplo em `flake.nix` (`desktop = mkHost { … }`).
5. Aplique: `sudo nixos-rebuild switch --flake /home/lin/nix#<nome>`.

## git (recomendado)

O `git` ainda não está instalado — ele entra junto no primeiro `switch`.
Depois, versione o flake:

```bash
cd /home/lin/nix
git init && git add . && git commit -m "config inicial"
```

> ⚠️ Com flakes em um repositório git, arquivos **não rastreados** são ignorados
> na avaliação. Sempre rode `git add .` antes de `nixos-rebuild` após criar
> arquivos novos.
