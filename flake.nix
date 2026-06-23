{
  description = "Configurações NixOS para múltiplas máquinas (flake multi-host)";

  inputs = {
    # nixpkgs no canal unstable.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # NixOS-WSL — o branch `main` acompanha o nixos-unstable.
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # home-manager para gerenciar a config de usuário; segue o mesmo nixpkgs.
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Claude Code empacotado com auto-update (sadjow/claude-code-nix).
    claude-code = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nixvim — Neovim 100% declarativo (config + plugins via Nix).
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # niri — compositor Wayland (scrollable-tiling). Traz módulo NixOS +
    # home-manager + overlay (niri-stable/niri-unstable) e cache binário.
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # noctalia — shell/bar Wayland (usado sobre o niri). Traz pacote +
    # módulos home-manager/NixOS + overlay.
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, home-manager, ... }@inputs:
    let
      inherit (nixpkgs) lib;

      # Helper para montar um host NixOS já com o home-manager integrado.
      # Cada máquina vive em ./hosts/<hostname>/ e herda ./modules/nixos.
      mkHost =
        {
          hostname,
          system ? "x86_64-linux",
          modules ? [ ],
        }:
        lib.nixosSystem {
          inherit system;
          # Torna `inputs` e `self` acessíveis dentro de todos os módulos.
          specialArgs = { inherit inputs self; };
          modules =
            [
              ./modules/nixos # config de sistema comum a todas as máquinas
              ./hosts/${hostname} # config específica desta máquina

              home-manager.nixosModules.home-manager
              {
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.extraSpecialArgs = { inherit inputs self; };
                # No 1º switch, faz backup de dotfiles pré-existentes (ex.: os
                # symlinks do antigo install.sh) em vez de abortar a ativação.
                home-manager.backupFileExtension = "hm-bak";
              }
            ]
            ++ modules;
        };
    in
    {
      nixosConfigurations = {
        # Esta máquina: NixOS rodando sob WSL2.
        nixos-wsl = mkHost {
          hostname = "nixos-wsl";
          modules = [ inputs.nixos-wsl.nixosModules.default ];
        };

        # Desktop x86_64 — CPU AMD + GPU AMD, greeter SDDM, compositor niri,
        # shell noctalia. Antes do 1º install, gere o hardware real com
        # `nixos-generate-config` (ver hosts/desktop/hardware-configuration.nix).
        desktop = mkHost {
          hostname = "desktop";
          modules = [
            ./hosts/desktop/hardware-configuration.nix
            # O módulo NixOS do niri também injeta automaticamente o módulo
            # home-manager (programs.niri.settings) em todos os usuários — por
            # isso home/desktop.nix NÃO importa o homeModule do niri de novo.
            inputs.niri.nixosModules.niri
          ];
        };

        # ── Para adicionar mais um PC ─────────────────────────────────────
        # 1. crie ./hosts/<nome>/default.nix (+ hardware-configuration.nix
        #    gerado por `nixos-generate-config`);
        # 2. no host, aponte o home-manager para a config daquela máquina:
        #      home-manager.users.lin = import ../../home/<nome>.nix;
        # 3. adicione um bloco `<nome> = mkHost { … }` aqui, espelhando o
        #    `desktop` acima.
      };
    };
}
