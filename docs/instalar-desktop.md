# Instalar o host `desktop` (fresh install pelo ISO)

Guia de ponta a ponta para instalar o host **`desktop`** (PC x86_64 AMD, SDDM →
niri → noctalia) numa máquina nova, bootando pelo ISO do NixOS.

> Resumo rápido: monta os discos em `/mnt` → clona o flake → **regera** o
> `hardware-configuration.nix` → **define a senha do `lin`** → `nixos-install`.

## 1. Boot pelo ISO + rede

Boot pelo ISO do NixOS e garanta internet:

```bash
ping -c1 github.com                       # cabo: costuma já funcionar
# wifi: nmcli device wifi connect "SSID" password "senha"
```

## 2. Particionar, formatar e montar em `/mnt`

Exemplo **UEFI + ext4** (ajuste os `/dev/...` ao seu disco — confira com `lsblk`):

```bash
sudo parted /dev/nvme0n1 -- mklabel gpt
sudo parted /dev/nvme0n1 -- mkpart ESP fat32 1MiB 1GiB
sudo parted /dev/nvme0n1 -- set 1 esp on
sudo parted /dev/nvme0n1 -- mkpart primary 1GiB 100%

sudo mkfs.fat -F32 -n BOOT /dev/nvme0n1p1
sudo mkfs.ext4 -L nixos   /dev/nvme0n1p2

sudo mount /dev/disk/by-label/nixos /mnt
sudo mkdir -p /mnt/boot
sudo mount /dev/disk/by-label/BOOT /mnt/boot
```

Os labels `nixos`/`BOOT` batem com o placeholder do repo, mas você vai **regerar**
o hardware no passo 4 de qualquer forma.

## 3. Trazer o flake para a máquina

O flake precisa estar em disco (com git, arquivos **não rastreados** são ignorados
na avaliação). Clone o repo já dentro do sistema instalado:

```bash
nix-shell -p git        # o ISO nem sempre traz git no PATH
git clone https://github.com/fnxln/nix.git /mnt/etc/nixos-flake
cd /mnt/etc/nixos-flake
```

## 4. Gerar o hardware real e substituir o placeholder

**Obrigatório** — o `hardware-configuration.nix` versionado é fictício (UUIDs
falsos) e não dá boot na máquina real:

```bash
sudo nixos-generate-config --root /mnt --show-hardware-config \
  > hosts/desktop/hardware-configuration.nix
git add hosts/desktop/hardware-configuration.nix
```

> O `git add` é essencial: sem ele o flake não enxerga o arquivo novo.

## 5. Definir a senha do `lin` ⚠️

O usuário `lin` **não tem senha definida** no flake (`initialPassword` está
comentado em `modules/nixos/common.nix`). No WSL isso não importa (login
automático), mas no desktop o **SDDM exige senha** para logar. Escolha **uma** das
opções:

- **A) Definir a senha após o install** (recomendado — não vaza senha no Nix):
  faça o passo 6 primeiro e depois rode:

  ```bash
  sudo nixos-enter --root /mnt -c 'passwd lin'
  ```

- **B) Senha inicial declarativa**: descomente e ajuste em
  `modules/nixos/common.nix` **antes** do install (troque na hora):

  ```nix
  users.users.lin.initialPassword = "troque-isto";
  ```

  Lembre de `git add -u` após editar. Troque a senha no primeiro login.

## 6. Instalar apontando para o host `desktop`

```bash
sudo nixos-install --flake /mnt/etc/nixos-flake#desktop \
  --option experimental-features 'nix-command flakes'
```

O `--option` é necessário porque o ambiente do ISO não habilita flakes por padrão.
Ao final ele pede a senha do `root`. Se escolheu a **opção A** do passo 5, rode o
`passwd lin` agora (antes de rebootar).

## 7. Reboot

```bash
reboot
```

No boot: aparece o **SDDM** → escolha a sessão **niri** → a **noctalia** sobe
sozinha (systemd user service). Atalhos: `Super+Return` (foot), `Super+D`
(launcher), `Super+B` (Firefox), `Super+/` (lista de binds).

## Notas

- O cache binário do niri (`niri.cachix.org`, via `niri-flake.cache.enable`)
  evita compilar o compositor durante o install.
- Confirme `system.stateVersion` em `hosts/desktop/default.nix` (use a versão que
  está instalando; não mude depois).
- `boot.loader.systemd-boot` assume **UEFI**. Se a placa fizer boot legado/BIOS,
  troque pelo GRUB (ver comentário no `hosts/desktop/default.nix`).
- O `lin` tem **sudo sem senha** (regra em `modules/nixos/common.nix`), mas isso
  **não** substitui a senha de login do SDDM — o passo 5 continua necessário.
