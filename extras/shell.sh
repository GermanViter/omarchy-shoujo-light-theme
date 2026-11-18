# Sourced from ~/.bashrc and ~/.zshrc by the Shoujo installer (install.sh).
# Remove it with: install.sh --uninstall

# eza lets LS_COLORS override its theme file, so LS_COLORS is cleared for eza
# alone. Its colors then come from ~/.config/eza/theme.yml, which Omarchy
# re-renders on every theme switch. Omarchy's `ls`, `lt` and `lsa` aliases call
# eza, so they pick this up too. The `function` keyword keeps zsh from expanding
# an alias named eza while defining it.
function eza {
  LS_COLORS= command eza "$@"
}
