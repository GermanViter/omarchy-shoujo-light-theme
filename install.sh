#!/usr/bin/env bash
#
# Shoujo for Omarchy: installs the theme and makes the tools Omarchy leaves
# alone follow it too.
#
#   bash <(curl -fsSL https://raw.githubusercontent.com/GermanViter/omarchy-shoujo-light-theme/main/install.sh)
#
# Omarchy already themes Hyprland, the bar, the terminals, Neovim, btop, the
# browser and more from a theme's colors.toml. This script adds Starship,
# Fastfetch and eza as Omarchy user templates (~/.config/omarchy/themed), which
# Omarchy re-renders on every theme switch, so they follow whichever theme is
# active. It also checks that every terminal still reads Omarchy's theme, links
# Neovim to it, and gives Kitty the Shoujo look.
#
# Anything it replaces is moved to ~/.local/share/omarchy-shoujo/backups first,
# and --uninstall puts it back.

set -euo pipefail

THEME_VARIANT="light" # dark or light: the variant this repo installs

REPO_OWNER="GermanViter"
STATE_DIR="$HOME/.local/share/omarchy-shoujo"
MANIFEST="$STATE_DIR/manifest"
SHELL_SNIPPET="$STATE_DIR/shell.sh"
BACKUP_DIR="$STATE_DIR/backups/$(date +%Y%m%d-%H%M%S)"
TEMPLATES_DIR="$HOME/.config/omarchy/themed"
THEMES_DIR="$HOME/.config/omarchy/themes"
CURRENT_THEME="$HOME/.local/state/omarchy/current/theme"
TEMPLATES=(starship.toml.tpl fastfetch.jsonc.tpl eza.yml.tpl)
MARK="omarchy-shoujo"
BLOCK_BEGIN="# >>> $MARK >>>"
BLOCK_END="# <<< $MARK <<<"
RC_LINE='[ -f "$HOME/.local/share/omarchy-shoujo/shell.sh" ] && . "$HOME/.local/share/omarchy-shoujo/shell.sh"'
RC_COMMENT="# Shoujo for Omarchy: eza follows the theme (undo with install.sh --uninstall)"

DRY_RUN=false
BOTH=false
TERMINAL_LOOK=true
UNINSTALL=false
EXTRAS=""
TMP_CLONE=""

# ── Output ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

log_info()    { echo -e "${BLUE}  →${RESET} $*"; }
log_success() { echo -e "${GREEN}  ✓${RESET} $*"; }
log_warn()    { echo -e "${YELLOW}  !${RESET} $*"; }
log_error()   { echo -e "${RED}  ✗${RESET} $*" >&2; }
log_step()    { echo -e "\n${BOLD}${CYAN}=== $* ===${RESET}"; }
pretty()      { echo "${1/#$HOME/\~}"; }

show_help() {
  cat <<EOF
Usage: install.sh [options]

Installs the Shoujo ${THEME_VARIANT^} theme for Omarchy and makes Starship, Fastfetch,
eza, the terminals and Neovim follow the active Omarchy theme.

Options:
  --both               Also install the other Shoujo variant (dark and light)
  --no-terminal-look   Keep Kitty's look as it is (colors still follow the theme)
  -n, --dry-run        Show what would change without changing anything
  -u, --uninstall      Undo everything this script did and restore the backups
  -h, --help           Show this help
EOF
}

# ── Helpers ──────────────────────────────────────────────────────────────────
repo_url() { echo "https://github.com/$REPO_OWNER/omarchy-shoujo-$1-theme.git"; }

# Omarchy may ask for a sudo password (the browser policy). When the script
# is piped into bash, stdin is the script itself, so read from the terminal.
with_tty() {
  if [[ ! -t 0 ]] && (exec </dev/tty) 2>/dev/null; then
    "$@" </dev/tty
  else
    "$@"
  fi
}

record() {
  $DRY_RUN && return 0
  mkdir -p "$STATE_DIR"
  printf '%s\t%s\t%s\n' "$1" "$2" "${3:-}" >>"$MANIFEST"
}

is_ours() {
  [[ -f $MANIFEST ]] && awk -F '\t' -v p="$1" '$1 == "created" && $2 == p { found = 1 } END { exit !found }' "$MANIFEST"
}

# Moves a file, directory or link the script is about to replace into the
# backup folder, and records where it went so --uninstall can bring it back.
move_aside() {
  local path=$1 dest="$BACKUP_DIR/${1#"$HOME"/}"

  if $DRY_RUN; then
    log_info "[dry run] Would back up $(pretty "$path")"
    return
  fi

  mkdir -p "${dest%/*}"
  mv "$path" "$dest"
  record backup "$path" "$dest"
  log_info "Backed up $(pretty "$path") to $(pretty "$dest")"
}

# Points a config file at the copy Omarchy renders into the current theme.
place_link() {
  local target=$1 link=$2

  if [[ -L $link && $(readlink -m "$link") == "$(readlink -m "$target")" ]]; then
    log_success "$(pretty "$link") already follows the theme"
    return
  fi

  if [[ -e $link || -L $link ]]; then
    if is_ours "$link"; then
      $DRY_RUN || rm -f "$link"
    else
      move_aside "$link"
    fi
  fi

  if $DRY_RUN; then
    log_info "[dry run] Would link $(pretty "$link") to $(pretty "$target")"
    return
  fi

  mkdir -p "${link%/*}"
  ln -s "$target" "$link"
  is_ours "$link" || record created "$link"
  log_success "Linked $(pretty "$link") to the theme"
}

# Removes this script's block from a config file, writing through symlinks so
# a dotfiles repo keeps its links.
remove_block() {
  local file=$1
  [[ -f $file ]] && grep -qxF "$BLOCK_BEGIN" "$file" || return 0
  $DRY_RUN && return 0
  sed -i --follow-symlinks "/^# >>> $MARK >>>\$/,/^# <<< $MARK <<<\$/d" "$file"
}

# Puts a marked block of lines at the top of a config file, replacing the one
# an earlier run left there. Settings further down the file still win.
prepend_block() {
  local file=$1 tmp
  shift

  remove_block "$file"
  (($#)) || return 0

  if $DRY_RUN; then
    log_info "[dry run] Would add to $(pretty "$file"): $*"
    return
  fi

  mkdir -p "${file%/*}"
  [[ -f $file ]] || : >"$file"
  tmp=$(mktemp)
  {
    echo "$BLOCK_BEGIN"
    printf '%s\n' "$@"
    echo "$BLOCK_END"
    cat "$file"
  } >"$tmp"
  # cat rather than mv, so a symlinked config stays a symlink.
  cat "$tmp" >"$file"
  rm -f "$tmp"
}

# ── Steps ────────────────────────────────────────────────────────────────────
preflight() {
  if ! command -v omarchy >/dev/null 2>&1 || ! command -v omarchy-theme-color >/dev/null 2>&1 ||
    [[ ! -d $HOME/.local/state/omarchy ]]; then
    log_error "This installer needs Omarchy 4 or newer."
    log_error "On Omarchy 3, install the theme alone with: omarchy-theme-install $(repo_url "$THEME_VARIANT")"
    exit 1
  fi
}

# Run from a checkout, the extras sit next to this script. Piped from curl,
# they come from a temporary clone.
resolve_extras() {
  local here=""
  here=$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd) || here=""

  if [[ -n $here && -f $here/extras/shell.sh ]]; then
    EXTRAS="$here/extras"
    return
  fi

  TMP_CLONE=$(mktemp -d)
  trap 'rm -rf "$TMP_CLONE"' EXIT
  log_info "Downloading the Shoujo extras"
  git clone --quiet --depth 1 "$(repo_url "$THEME_VARIANT")" "$TMP_CLONE/repo"
  EXTRAS="$TMP_CLONE/repo/extras"
}

install_packages() {
  local missing=() tool

  for tool in starship fastfetch eza; do
    command -v "$tool" >/dev/null 2>&1 || missing+=("$tool")
  done

  if ((${#missing[@]} == 0)); then
    log_success "Starship, Fastfetch and eza are installed"
  elif $DRY_RUN; then
    log_info "[dry run] Would install: ${missing[*]}"
  else
    with_tty omarchy pkg add "${missing[@]}"
  fi
}

install_templates() {
  local name src dest

  for name in "${TEMPLATES[@]}"; do
    src="$EXTRAS/$name"
    dest="$TEMPLATES_DIR/$name"

    if [[ -f $dest && ! -L $dest ]] && cmp -s "$src" "$dest"; then
      log_success "Template $(pretty "$dest") is up to date"
      continue
    fi

    if [[ -e $dest || -L $dest ]] && ! is_ours "$dest"; then
      move_aside "$dest"
    fi

    if $DRY_RUN; then
      log_info "[dry run] Would install the template $(pretty "$dest")"
      continue
    fi

    mkdir -p "$TEMPLATES_DIR"
    rm -f "$dest"
    cp "$src" "$dest"
    chmod 644 "$dest"
    is_ours "$dest" || record created "$dest"
    log_success "Installed the template $(pretty "$dest")"
  done
}

link_configs() {
  place_link "$CURRENT_THEME/starship.toml" "$HOME/.config/starship.toml"
  place_link "$CURRENT_THEME/fastfetch.jsonc" "$HOME/.config/fastfetch/config.jsonc"
  place_link "$CURRENT_THEME/eza.yml" "${EZA_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/eza}/theme.yml"

  if [[ -n ${STARSHIP_CONFIG:-} && $(readlink -m "$STARSHIP_CONFIG") != "$(readlink -m "$HOME/.config/starship.toml")" ]]; then
    log_warn "STARSHIP_CONFIG points to $(pretty "$STARSHIP_CONFIG"), so Starship won't read the themed prompt until you unset it"
  fi
}

setup_shell() {
  local rc

  if $DRY_RUN; then
    log_info "[dry run] Would install $(pretty "$SHELL_SNIPPET")"
  else
    mkdir -p "$STATE_DIR"
    cp "$EXTRAS/shell.sh" "$SHELL_SNIPPET"
    log_success "Installed $(pretty "$SHELL_SNIPPET")"
  fi

  for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    [[ -f $rc ]] || continue

    if grep -qF "omarchy-shoujo/shell.sh" "$rc"; then
      log_success "$(pretty "$rc") already loads it"
    elif $DRY_RUN; then
      log_info "[dry run] Would add one line to $(pretty "$rc")"
    else
      # Start on a fresh line, without the blank line that would outlive --uninstall.
      [[ -s $rc && -n $(tail -c 1 "$rc") ]] && echo >>"$rc"
      printf '%s\n%s\n' "$RC_COMMENT" "$RC_LINE" >>"$rc"
      log_success "$(pretty "$rc") now loads it"
    fi
  done
}

# Each terminal reads its colors from a file in the current Omarchy theme.
# Stock Omarchy configs already include it; this puts it back in one that lost
# it, and gives Kitty the Shoujo look.
setup_terminals() {
  local kitty="$HOME/.config/kitty/kitty.conf"
  local ghostty="$HOME/.config/ghostty/config"
  local foot="$HOME/.config/foot/foot.ini"
  local alacritty="$HOME/.config/alacritty/alacritty.toml"
  local lines

  if [[ -f $kitty ]] || command -v kitty >/dev/null 2>&1; then
    remove_block "$kitty"
    lines=()
    if $TERMINAL_LOOK; then
      lines+=(
        "# Shoujo look. Your own settings further down, and Omarchy's Glassy mode, still win."
        "background_opacity 0.9"
        "background_blur 32"
        "cursor_trail 1"
        "window_margin_width 10"
      )
    fi
    if [[ ! -f $kitty ]] || ! grep -qF "omarchy/current/theme/kitty.conf" "$kitty"; then
      lines+=("include ~/.local/state/omarchy/current/theme/kitty.conf")
    fi
    prepend_block "$kitty" "${lines[@]}"
    log_success "Kitty follows the theme"
  fi

  if [[ -f $ghostty ]]; then
    remove_block "$ghostty"
    if ! grep -qF "omarchy/current/theme/ghostty.conf" "$ghostty"; then
      prepend_block "$ghostty" 'config-file = ?"~/.local/state/omarchy/current/theme/ghostty.conf"'
    fi
    log_success "Ghostty follows the theme"
  fi

  if [[ -f $foot ]]; then
    remove_block "$foot"
    if ! grep -qF "omarchy/current/theme/foot.ini" "$foot"; then
      prepend_block "$foot" "include=~/.local/state/omarchy/current/theme/foot.ini"
    fi
    log_success "Foot follows the theme"
  fi

  if [[ -f $alacritty ]]; then
    remove_block "$alacritty"
    if grep -qF "omarchy/current/theme/alacritty.toml" "$alacritty"; then
      log_success "Alacritty follows the theme"
    elif grep -qE '^[[:space:]]*(\[general\]|general\.)' "$alacritty"; then
      # A second general table would make the TOML invalid.
      log_warn "Add \"~/.local/state/omarchy/current/theme/alacritty.toml\" to general.import in $(pretty "$alacritty") so Alacritty follows the theme"
    else
      prepend_block "$alacritty" 'general.import = [ "~/.local/state/omarchy/current/theme/alacritty.toml" ]'
      log_success "Alacritty follows the theme"
    fi
  fi
}

# Omarchy's LazyVim setup loads the theme through plugins/theme.lua, a link to
# the current theme's neovim.lua.
setup_neovim() {
  local plugins="$HOME/.config/nvim/lua/plugins"

  if [[ ! -d $plugins ]]; then
    log_warn "No LazyVim config in $(pretty "$HOME/.config/nvim"), so Neovim was left alone"
    return
  fi

  place_link "$CURRENT_THEME/neovim.lua" "$plugins/theme.lua"
}

install_theme() {
  local variant=$1 apply=$2
  local name="shoujo-$variant" dir="$THEMES_DIR/shoujo-$variant"

  # A copy the user keeps themselves (no .git, or a link to their own working
  # copy). `omarchy theme install` would delete it, so leave it be.
  if [[ -L $dir || (-d $dir && ! -d $dir/.git) ]]; then
    log_info "Keeping your own copy of $name in $(pretty "$dir")"
    if $apply; then
      if $DRY_RUN; then log_info "[dry run] Would run: omarchy theme set $name"; else with_tty omarchy theme set "$name"; fi
    fi
    return
  fi

  if $apply; then
    if $DRY_RUN; then
      log_info "[dry run] Would run: omarchy theme install $(repo_url "$variant")"
    else
      with_tty omarchy theme install "$(repo_url "$variant")"
    fi
  elif $DRY_RUN; then
    log_info "[dry run] Would download $name into $(pretty "$dir")"
  else
    # What `omarchy theme install` does, without switching to it.
    rm -rf "$dir"
    git clone --quiet "$(repo_url "$variant")" "$dir"
    log_success "Downloaded $name (pick it any time from the theme menu)"
  fi
}

verify() {
  local file missing=()

  $DRY_RUN && return 0
  for file in starship.toml fastfetch.jsonc eza.yml; do
    [[ -f $CURRENT_THEME/$file ]] || missing+=("$file")
  done

  if ((${#missing[@]})); then
    log_warn "Omarchy didn't render ${missing[*]} into the current theme. Run: omarchy theme set shoujo-$THEME_VARIANT"
  else
    log_success "Starship, Fastfetch and eza are rendered with the current theme's colors"
  fi
}

uninstall() {
  local rc file kind path backup

  log_step "Removing the shell hook"
  for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [[ -f $rc ]] && grep -qF "omarchy-shoujo/shell.sh" "$rc"; then
      if $DRY_RUN; then
        log_info "[dry run] Would remove the line from $(pretty "$rc")"
      else
        sed -i --follow-symlinks -e '/^# Shoujo for Omarchy: eza follows the theme/d' -e '/omarchy-shoujo\/shell\.sh/d' "$rc"
        log_success "Cleaned $(pretty "$rc")"
      fi
    fi
  done

  log_step "Removing the terminal blocks"
  for file in "$HOME/.config/kitty/kitty.conf" "$HOME/.config/ghostty/config" \
    "$HOME/.config/foot/foot.ini" "$HOME/.config/alacritty/alacritty.toml"; do
    if [[ -f $file ]] && grep -qxF "$BLOCK_BEGIN" "$file"; then
      remove_block "$file"
      log_success "Cleaned $(pretty "$file")"
    fi
  done

  if [[ ! -f $MANIFEST ]]; then
    log_info "Nothing else to undo"
  else
    log_step "Removing links and templates"
    while IFS=$'\t' read -r kind path backup; do
      [[ $kind == created ]] || continue
      [[ -e $path || -L $path ]] || continue
      if $DRY_RUN; then log_info "[dry run] Would remove $(pretty "$path")"; else rm -f "$path" && log_success "Removed $(pretty "$path")"; fi
    done <"$MANIFEST"

    log_step "Restoring backups"
    while IFS=$'\t' read -r kind path backup; do
      [[ $kind == backup ]] || continue
      if [[ ! -e $backup && ! -L $backup ]]; then
        continue
      elif [[ -e $path || -L $path ]]; then
        log_warn "$(pretty "$path") exists, so its backup stays in $(pretty "$backup")"
      elif $DRY_RUN; then
        log_info "[dry run] Would restore $(pretty "$path")"
      else
        mkdir -p "${path%/*}"
        mv "$backup" "$path"
        log_success "Restored $(pretty "$path")"
      fi
    done < <(tac "$MANIFEST")
  fi

  if ! $DRY_RUN; then
    rm -f "$MANIFEST" "$SHELL_SNIPPET"
    [[ -d $STATE_DIR ]] && find "$STATE_DIR" -depth -type d -empty -delete
  fi

  echo
  log_success "Shoujo extras removed. The themes stay installed; switch themes from the Omarchy menu."
}

# ── Main ─────────────────────────────────────────────────────────────────────
main() {
  while (($#)); do
    case $1 in
      --both) BOTH=true ;;
      --no-terminal-look) TERMINAL_LOOK=false ;;
      -n | --dry-run) DRY_RUN=true ;;
      -u | --uninstall) UNINSTALL=true ;;
      -h | --help) show_help; exit 0 ;;
      *) log_error "Unknown option: $1"; show_help; exit 1 ;;
    esac
    shift
  done

  $DRY_RUN && log_warn "Dry run: nothing will be changed"

  if $UNINSTALL; then
    uninstall
    return
  fi

  preflight

  log_step "Shoujo ${THEME_VARIANT^} for Omarchy"
  resolve_extras

  log_step "Packages"
  install_packages

  log_step "Starship, Fastfetch and eza"
  install_templates
  link_configs
  setup_shell

  log_step "Terminals"
  setup_terminals

  log_step "Neovim"
  setup_neovim

  log_step "Theme"
  if $BOTH; then
    local other=light
    [[ $THEME_VARIANT == light ]] && other=dark
    install_theme "$other" false
  fi
  install_theme "$THEME_VARIANT" true
  verify

  echo
  log_success "Done. Open a new terminal to see everything in Shoujo ${THEME_VARIANT^}."
  log_info "Switching to any other Omarchy theme recolors all of it too."
  log_info "Undo with: install.sh --uninstall (backups are in $(pretty "$STATE_DIR"))"
}

main "$@"
exit
