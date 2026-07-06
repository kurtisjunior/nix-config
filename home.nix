{ pkgs, ... }:
{
  home.username = "kurtis";
  home.homeDirectory = "/Users/kurtis";
  home.stateVersion = "24.11";   # leave this; it pins compatibility
  programs.home-manager.enable = true; 

  # ── Your global toolbelt: add/remove tools here ──
  home.packages = with pkgs; [
    git
    jq
    eza
    gh 
  ];

#*** everyday loop, edit home.nix then run: hms

  # We declare "~/.local/bin should be on my PATH" HERE, up front.
  home.sessionPath = [ "$HOME/.local/bin" ];

  # Home Manager owns your shell (this creates ~/.zshrc for you).
  programs.zsh = {
  enable = true;                # you already have this
  shellAliases = {
    ls = "eza --icons=always -a --group-directories-first";
    ggpush = "git push";
    hms = "home-manager switch --flake ~/nix-config#kurtis";
  };
};

  # direnv powers the per-project layer in Step 5.
  # Because zsh is managed above, the direnv hook is wired in automatically.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
