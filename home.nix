{ pkgs, lib, ... }:
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
    zsh-powerlevel10k
  ];

  #*** everyday loop, edit home.nix then run: hms

  # We declare "~/.local/bin should be on my PATH" HERE, up front.
  home.sessionPath = [ "$HOME/.local/bin" ];

  # Home Manager owns your shell (this creates ~/.zshrc for you).
  programs.zsh = {
    enable = true;
    defaultKeymap = "viins";

    initContent = lib.mkMerge [
      # p10k instant prompt MUST be at the very top
      (lib.mkBefore ''
        if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
          source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
        fi
      '')

      ''
        source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
        [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

        bindkey '^R' history-incremental-search-backward
        bindkey '^F' history-incremental-search-forward
        setopt auto_cd

        export KEYTIMEOUT=1

        # Vi mode cursor: block in normal, beam in insert
        function zle-keymap-select {
          if [[ ''${KEYMAP} == vicmd ]] || [[ $1 = 'block' ]]; then
            echo -ne '\e[1 q'
          elif [[ ''${KEYMAP} == main ]] || [[ ''${KEYMAP} == viins ]] || [[ ''${KEYMAP} = "" ]] || [[ $1 = 'beam' ]]; then
            echo -ne '\e[5 q'
          fi
        }
        zle -N zle-keymap-select

        function zle-line-init {
          zle -K viins
          echo -ne "\e[5 q"
        }
        zle -N zle-line-init
        echo -ne '\e[5 q'
        preexec() { echo -ne '\e[5 q'; }

        # Tab completion
        autoload -U compinit
        zstyle ':completion:*' menu select
        zmodload zsh/complist
        compinit
        _comp_options+=(globdots)

        function git_current_branch() {
          git rev-parse --abbrev-ref HEAD 2>/dev/null
        }
      ''
    ];

    shellAliases = {
      hms = "home-manager switch --flake ~/nix-config#kurtis";

      # shell
      ls      = "eza --icons=always -a --group-directories-first";
      history = "history 1";
      arsenal = "python ~/projects/arsenalScript/ars.py";

      # git
      gst    = "git status";
      gco    = "git checkout";
      gsc    = "git stash clear";
      ggpull = "git pull --rebase";
      ggpush = "git push origin $(git rev-parse --abbrev-ref HEAD)";
      glol   = "git log --graph --pretty='%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%ar) %C(bold blue)<%an>%Creset' -n 20";
      gloll  = "git log --pretty=oneline -n 20 --graph --abbrev-commit --decorate --all";
      gcane  = "git commit --amend --no-edit";
    };
  };

  programs.vim = {
    enable = true;
    extraConfig = ''
      set backspace=indent,eol,start
    '';
  };

  # direnv powers the per-project layer in Step 5.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
