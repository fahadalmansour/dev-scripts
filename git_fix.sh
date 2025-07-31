#!/usr/bin/env bash
# ===========================================
#  git_fix.sh  –  one-click bootstrap + sync
# ===========================================
set -euo pipefail
cyan(){ printf "\e[36m%s\e[0m\n" "$1"; }
red(){  printf "\e[31m%s\e[0m\n"  "$1"; }

## ——— إعداد متغيراتك هنا —————————————————— ##
GH_USER="fahadalmansour"
REPO_NAME="dashboard_stack"
PROJECT_DIR="/Volumes/free/projects/dashboard"
REMOTE_URL="https://github.com/${GH_USER}/${REPO_NAME}.git"
DEFAULT_BRANCH="main"
## ———————————————————————————————————————— ##

[[ -z "${GITHUB_TOKEN:-}" ]] && { red "❌  GITHUB_TOKEN غير موجود فى البيئة"; exit 1; }

# 0) إصلاح zsh-autocomplete permissions
cyan "🔧  Fixing zsh-autocomplete permissions…"
mkdir -p "$HOME/.local/state/zsh-autocomplete/log"
chmod -R u+rw "$HOME/.local/state/zsh-autocomplete"

# 1) إعداد git global (لو لم تُضبط من قبل)
git config --global init.defaultBranch "$DEFAULT_BRANCH"

# 2) تأكد من وجود المجلد و git init
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"
if [[ ! -d .git ]]; then
  cyan "📝  Initialising new git repo…"
  git init -q
fi

# 3) إضافة remote إن لم يوجد
if ! git remote get-url origin &>/dev/null; then
  cyan "➕  Adding remote → $REMOTE_URL"
  git remote add origin "$REMOTE_URL"
fi

# 4) التأكد من وجود الريبو على GitHub أو إنشائه
if ! gh repo view "${GH_USER}/${REPO_NAME}" &>/dev/null; then
  cyan "📦  GitHub repo not found – creating…"
  gh repo create "${GH_USER}/${REPO_NAME}" --private --confirm
fi

# 5) جلب آخر تاريخ من الريبو (إن وجد)
cyan "🔄  Fetching from GitHub…"
git fetch origin "$DEFAULT_BRANCH" || true

LOCAL_HAS_COMMITS=$(git rev-parse --quiet --verify "${DEFAULT_BRANCH}" || echo "")
REMOTE_HAS_COMMITS=$(git ls-remote --heads origin "$DEFAULT_BRANCH" | wc -l)

# 6) مزامنة التاريخ
if [[ -n "$LOCAL_HAS_COMMITS" && $REMOTE_HAS_COMMITS -gt 0 ]]; then
  cyan "🔀  Rebasing local → origin/$DEFAULT_BRANCH"
  git checkout "$DEFAULT_BRANCH"
  git rebase "origin/$DEFAULT_BRANCH" || {
     red "⚠️  Rebase فشل – استخدام merge بدلاً"
     git merge --strategy-option theirs "origin/$DEFAULT_BRANCH"
  }
elif [[ $REMOTE_HAS_COMMITS -gt 0 ]]; then
  cyan "⬇️   Pulling remote branch…"
  git checkout -B "$DEFAULT_BRANCH" "origin/$DEFAULT_BRANCH"
else
  cyan "⬆️   Pushing first commit to GitHub…"
  [[ -z "$LOCAL_HAS_COMMITS" ]] && { touch .init && git add .init && git commit -m "init"; }
  git push -u origin "$DEFAULT_BRANCH"
fi

# 7) حل أى رفض Push لاحقاً
cyan "🚀  Final push with --force-with-lease (safe-force)…"
git push --force-with-lease origin "$DEFAULT_BRANCH"

cyan "✅  كل شيء تزامن!"
echo "
• المسار: $PROJECT_DIR
• الريبو:  $REMOTE_URL
"
