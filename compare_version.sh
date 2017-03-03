#!/bin/bash

# Compare lates and built version for each package and generate a new .travis.yml with updated matrix from that.

compare () {
  export LATEST_PKGVER=$(curl -s https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=${1} 2>&1 | grep -Poi '^pkgver=(.*)$' | cut -d= -f2 | sed 's/"//g')
  export LATEST_PKGREL=$(curl -s https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=${1} 2>&1 | grep -Poi '^pkgrel=(.*)$' | cut -d= -f2 | sed 's/"//g')

  BUILT_PKGVER=$(curl -s --fail https://aurbot.github.io/meta/${1}.pkgver)
  BUILT_PKGREL=$(curl -s --fail https://aurbot.github.io/meta/${1}.pkgrel)

  if [ "${LATEST_PKGVER}" = "${BUILT_PKGVER}" ] && [ "${LATEST_PKGREL}" = "${BUILT_PKGREL}" ]; then
    return 0
  else
    return 1
  fi
}

if [ "${PACKAGE}" = "__compare__" ]; then
  # start with empty matrix list
  mv .travis.yml .travis.yml.previous
  cp .travis.yml.empty .travis.yml

  # add packages to matrix that are not up-to-date
  while read pkg; do
    if ! compare $pkg; then
      echo "    - PACKAGE=$pkg" >> .travis.yml
    fi
  done <packages

  # always add compare check to end of list
  echo "    - PACKAGE=__compare__" >> .travis.yml
  
  # only commit if .travis.yml has actually changed, otherwise don't to avoid infinite loop.
  if ! diff -q .travis.yml .travis.yml.previous ; then
    # commit new .travis.yml to repo to trigger new builds.
    git remote remove origin
    git remote add origin "https://${GITHUB_TOKEN}@${AURBOT_REF:-github.com/aurbot/aurbot}" 
    git config user.name "${GITHUB_USER_NAME:-aurbot}"
    git config user.email "${GITHUB_USER_EMAIL:-aurbot@jankoppe.de}"
    git add .travis.yml
    git commit -m "aurbot added out-of-date packages to .travis.yml"
    git push origin HEAD:master
  fi
  exit 0
fi