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
    pkgs = nixpkgs.legacyPackages.${system};
    mermaidAscii = pkgs.buildGoModule {
      pname = "mermaid-ascii";
      version = "unstable";
      src = inputs."mermaid-ascii";
      vendorHash = "sha256-aB9sbTtlHbptM2995jizGFtSmEIg3i8zWkXz1zzbIek=";

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
