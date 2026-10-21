{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    mermaid-ascii = {
      url = "github:AlexanderGrooff/mermaid-ascii";
      flake = false;
    };
  };

  outputs = { nixpkgs, home-manager, ... }@inputs:
  let
    system = "aarch64-darwin";   # Apple Silicon. Use "x86_64-darwin" on Intel Macs.
    # Amp ships under a proprietary license, so nixpkgs refuses it unless we
    # opt in. Allow it by name rather than enabling unfree across the board.
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfreePredicate = pkg:
        builtins.elem (nixpkgs.lib.getName pkg) [ "amp-cli" ];

      # vim's GUI build is broken on darwin in current nixpkgs: image.c
      # references Gui.scale, which that struct no longer has. We only use vim
      # in the terminal, so build it without the GUI.
      overlays = [
        (final: prev: {
          vim-full = prev.vim-full.override { guiSupport = false; };
        })
      ];
    };
    mermaidAscii = pkgs.buildGoModule {
      pname = "mermaid-ascii";
      version = "unstable";
      src = inputs."mermaid-ascii";

      # Upstream ships a vendor/ directory that has drifted out of sync with
      # go.mod. Drop it and let Nix resolve the dependencies from go.mod.
      postPatch = "rm -rf vendor";
      vendorHash = "sha256-S/K6W8KC6YzwZPioucoiwOMd29LPv0J22T3MS0X+W5g=";

      meta = {
        description = "Render Mermaid diagrams in a terminal";
        homepage = "https://github.com/AlexanderGrooff/mermaid-ascii";
        license = pkgs.lib.licenses.mit;
        mainProgram = "mermaid-ascii";
      };
    };
  in {
    homeConfigurations.kurtis = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = {
        mermaid-ascii = mermaidAscii;
      };
      modules = [ ./home.nix ];
    };
  };
}
