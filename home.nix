{ pkgs, lib, config, mermaid-ascii, ... }:

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
    nodejs
    mermaid-ascii
  ];

  # ── Ghostty ────────────────────────────────────────────────────────────────
  # Ghostty itself is installed separately on macOS; Home Manager owns the
  # configuration at ~/.config/ghostty/config.
  programs.ghostty = {
    enable = true;
    package = null;

    settings = {
      # Rose Pine Moon palette, translucent background, and a soft macOS blur.
      theme = "rose-pine-moon";
      background-opacity = 0.7;
      background-blur = true;

      # Typography and spacing.
      font-family = "Hack Nerd Font";
      font-size = 14;
      window-padding-x = 12;
      window-padding-y = 10;

      # macOS tabs integrated into the title bar.
      macos-titlebar-style = "tabs";
      macos-window-buttons = "visible";
      window-title-font-family = "Hack Nerd Font";

      # Dim inactive split panes like WezTerm's inactive_pane_hsb setting.
      unfocused-split-opacity = 0.5;

      shell-integration = "zsh";
      confirm-close-surface = false;
    };
  };
  # Ensure Home Manager's generated config replaces any existing Ghostty config.
  xdg.configFile."ghostty/config".force = true;

  # ── Git ──────────────────────────────────────────────────────────────────────
  programs.git = {
    enable = true;
    settings.user.name  = "kurtis";
    settings.user.email = "kurtisangell@gmail.com";
    includes = [
      { condition = "gitdir:~/tinker/"; path = "~/tinker/.gitconfig"; }
      { condition = "gitdir:~/tw/";     path = "~/tw/.gitconfig"; } 
      { condition = "gitdir:~/hchb/";     path = "~/hchb/.gitconfig"; }
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
  
  home.file."hchb/.gitconfig" = {
    force = true;
    text = ''
      [user]
        name  = kurtis
        email = kangell@hchb.com
    '';
  };

  # ── Environment ──────────────────────────────────────────────────────────────
  home.sessionPath = [ "$HOME/.local/bin" "$HOME/.npm-global/bin" "$HOME/.rd/bin" ];

  # ── Shell (zsh) ──────────────────────────────────────────────────────────────
  programs.zsh = {
    enable        = true;
    defaultKeymap = "viins";

    initContent = lib.mkMerge [

      # direnv's initial environment export must happen before p10k's instant
      # prompt. Silence routine direnv/nix-direnv status messages.
      (lib.mkBefore ''
        export DIRENV_LOG_FORMAT=""
        (( ''${+commands[direnv]} )) && emulate zsh -c "$(direnv export zsh)"
      '')

      # p10k instant prompt must source before the remaining initialization
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

  # ── Prompt theme ─────────────────────────────────────────────────────────────
  # ~/.p10k.zsh is generated by `p10k configure` and sourced from .zshrc above;
  # without it the powerlevel10k prompt falls back to unstyled defaults. Linked
  # out of store so re-running the p10k wizard can still rewrite it in place.
  home.file.".p10k.zsh".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-config/p10k.zsh";

  # ── tmux ─────────────────────────────────────────────────────────────────────
  # Ghostty draws no tab strip inside a window, so tmux supplies the window list
  # along the top. Prefix stays C-b; sensibleOnTop adds tmux-sensible defaults.
  programs.tmux = {
    enable       = true;
    baseIndex    = 1;                # windows start at 1 to match the number row
    escapeTime   = 0;                # no ESC delay when dropping back to normal mode
    keyMode      = "vi";             # match the viins keymap used in zsh
    mouse        = true;
    historyLimit = 50000;
    terminal     = "tmux-256color";

    extraConfig = ''
      # True colour passthrough so the Ghostty theme survives inside tmux.
      set -ga terminal-overrides ",xterm-256color:Tc,ghostty:Tc"

      # Status bar on top: window list left, date right.
      set  -g status-position top
      set  -g status-left ""
      set  -g status-right "%Y-%m-%d %H:%M"
      set  -g status-right-length 40
      setw -g automatic-rename on

      # Splits that keep the current directory, with intuitive keys.
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"

      # Navigate panes with the same hjkl used everywhere else.
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      bind r source-file ~/.config/tmux/tmux.conf \; display "reloaded"
    '';
  };

  # ── Vim ──────────────────────────────────────────────────────────────────────
  programs.vim = {
    enable = true;
    extraConfig = ''
      set backspace=indent,eol,start
    '';
  };

  # ── Agent instructions ───────────────────────────────────────────────────────
  # AGENTS.md is the cross-tool convention (Codex, Copilot, etc.); Claude Code
  # reads ~/.claude/CLAUDE.md. Both names point at the one file in this repo so
  # the two copies can never drift apart. mkOutOfStoreSymlink targets the working
  # copy rather than the read-only nix store, so edits apply without running hms.
  home.file."AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-config/AGENTS.md";

  home.file.".claude/CLAUDE.md".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix-config/AGENTS.md";

  # ── Direnv ───────────────────────────────────────────────────────────────────
  # Per-project env vars via .envrc files; nix-direnv caches nix shells
  programs.direnv = {
    enable            = true;
    nix-direnv.enable = true;
  };
}
