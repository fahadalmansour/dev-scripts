#!/usr/bin/env bash
# ------------------------------------------------------------
# heal_zsh.sh  (mac-safe)  –  fixes Oh-My-Zsh insecure paths
# ------------------------------------------------------------
set -euo pipefail

cyan(){ printf '\e[36m%s\e[0m\n' "$1"; }
warn(){ printf '\e[33m%s\e[0m\n' "$1"; }

HOME_ZSHRC="$HOME/.zshrc"
OMZ_DIR="$HOME/.oh-my-zsh"

# 1) تأمين .zshrc
cyan "🔧  fixing ~/.zshrc …"
[[ -f "$HOME_ZSHRC" ]] || echo '# created by heal_zsh.sh' > "$HOME_ZSHRC"
grep -v 'oh-my-zsh\.sh' "$HOME_ZSHRC" >"${HOME_ZSHRC}.tmp" && mv "${HOME_ZSHRC}.tmp" "$HOME_ZSHRC"

# 2) تثبيت Oh-My-Zsh إذا لزم
if [[ ! -d "$OMZ_DIR" ]]; then
  cyan "🛠️  installing Oh-My-Zsh (unattended)…"
  RUNZSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# 3) إضافة السطور الصحيحة
grep -qx 'export ZSH="$HOME/.oh-my-zsh"' "$HOME_ZSHRC" || \
  echo 'export ZSH="$HOME/.oh-my-zsh"' >> "$HOME_ZSHRC"
grep -qx 'source $ZSH/oh-my-zsh.sh' "$HOME_ZSHRC"   || \
  echo 'source $ZSH/oh-my-zsh.sh'   >> "$HOME_ZSHRC"

# 4) إصلاح التصاريح بدون mapfile
cyan "🔒  fixing insecure permissions …"
INSECURE=$(zsh -c 'autoload -Uz compaudit && compaudit || true')
if [[ -n "$INSECURE" ]]; then
  while IFS='' read -r path; do
    [[ -z "$path" ]] && continue
    [[ -L "$path" ]] && path=$(readlink "$path")
    sudo chown -h "$USER":staff "$path" 2>/dev/null || true
    sudo chmod go-w   "$path"           2>/dev/null || true
  done <<< "$INSECURE"
  cyan "✅  permissions fixed for $(echo "$INSECURE" | wc -l | tr -d ' ') items"
else
  cyan "✅  no insecure paths reported"
fi

# 5) إعادة تحميل zsh
exec zsh -lc 'echo -e "\e[32m🎉  Zsh loaded cleanly.\e[0m"'
