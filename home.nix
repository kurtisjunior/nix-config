{ pkgs, lib, ... }:

{
  # ── Identity ────────────────────────────────────────────────────────────────
  home.username    = "kurtis";
  home.homeDirectory = "/Users/kurtis";
  home.stateVersion  = "24.11"; # pins HM compatibility — do not change
  programs.home-manager.enable = true;

  # ── Packages ─────────────────────────────────────────────────────────────────
  # CLI tools managed by nix. To apply changes: hms
  home.packages = with pkgs; [
    gh
    jq
    eza
    zsh-powerlevel10k
  ];

  # ── Git ──────────────────────────────────────────────────────────────────────
  programs.git = {
    enable = true;
    settings.user.name  = "kurtis";
    settings.user.email = "kurtisangell@gmail.com";
    includes = [
      { condition = "gitdir:~/tinker/"; path = "~/tinker/.gitconfig"; }
      { condition = "gitdir:~/tw/";     path = "~/tw/.gitconfig"; }
    ];
  };

  home.file."tinker/.gitconfig" = {
    force = true;
    text = ''
      [user]
        name  = kurtis
        email = kurtisangell@gmail.com
    '';
  };

  home.file."tw/.gitconfig" = {
    force = true;
    text = ''
      [user]
        name  = kurtis
        email = kurtis.angell@thoughtworks.com
    '';
  };

  # ── Environment ──────────────────────────────────────────────────────────────
  home.sessionPath = [ "$HOME/.local/bin" ];

  # ── Shell (zsh) ──────────────────────────────────────────────────────────────
  programs.zsh = {
    enable        = true;
    defaultKeymap = "viins";

    initContent = lib.mkMerge [

      # p10k instant prompt must source before anything else
      (lib.mkBefore ''
        if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
          source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
        fi
      '')

      ''
        # ── Prompt ────────────────────────────────────────────────────────────
        source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
        [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

        # ── Vi mode ───────────────────────────────────────────────────────────
        export KEYTIMEOUT=1

        bindkey '^R' history-incremental-search-backward
        bindkey '^F' history-incremental-search-forward

        # Switch cursor: block in normal mode, beam in insert mode
        function zle-keymap-select {
          if [[ ''${KEYMAP} == vicmd ]] || [[ $1 = 'block' ]]; then
            echo -ne '\e[1 q'
          elif [[ ''${KEYMAP} == main ]] || [[ ''${KEYMAP} == viins ]] || \
               [[ ''${KEYMAP} = "" ]]   || [[ $1 = 'beam' ]]; then
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

        # ── Completion ────────────────────────────────────────────────────────
        zstyle ':completion:*' menu select
        zmodload zsh/complist
        _comp_options+=(globdots) # include hidden files

        # ── Options ───────────────────────────────────────────────────────────
        setopt auto_cd            # type a dir name to cd into it

        # ── Functions ─────────────────────────────────────────────────────────
        function git_current_branch() {
          git rev-parse --abbrev-ref HEAD 2>/dev/null
        }
      ''
    ];

    shellAliases = {
      # nix
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

  # ── Vim ──────────────────────────────────────────────────────────────────────
  programs.vim = {
    enable = true;
    extraConfig = ''
      set backspace=indent,eol,start
    '';
  };

  # ── Direnv ───────────────────────────────────────────────────────────────────
  # Per-project env vars via .envrc files; nix-direnv caches nix shells
  programs.direnv = {
    enable            = true;
    nix-direnv.enable = true;
  };
}
