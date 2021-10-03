#!/bin/bash
set -euo pipefail

mv update_patch.sh update_patch_tmp.sh
finish() {
  mv update_patch_tmp.sh update_patch.sh 2>/dev/null | true
}
trap finish EXIT

setup_remote() {
  if $(git remote | grep -q "^$1$"); then
    git remote set-url $1 $2
  else
    git remote add $1 $2
  fi
}

merge() {
  git fetch $1 $2
  git merge $1/$2 || (
    if [ -f .git/MERGE_HEAD ]; then
      echo "> Fix conflict, commit, and press Enter to continue."
      read
    else
      exit 1
    fi
  )
}

setup_remote upstream git@github.com:denoland/rusty_v8.git
setup_remote piscisaureus git@github.com:piscisaureus/safe_v8.git

git fetch upstream main
git checkout patched
git reset --hard upstream/main

merge origin patches
# merge piscisaureus uplol_locker
merge origin feat/pub_drop_annex

sed -i "/version = /c\version = \"0.0.$(date -u +'%Y%m%d%H%M%S'\")" Cargo.toml
cargo check

mv update_patch_tmp.sh update_patch.sh
git add .
git commit -m "patched"
git push origin patched --force
mv update_patch.sh update_patch_tmp.sh

git checkout patched-crate
git reset --hard patched

rm -rf base build buildtools third_party tools v8 .github .gitmodules

mv update_patch_tmp.sh update_patch.sh
git add .
git commit -m "patched"
git push origin patched-crate --force

git checkout patched
