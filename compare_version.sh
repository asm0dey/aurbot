#!/bin/bash

# Compare lates and built version for each package and generate a new .travis.yml with updated matrix from that.

compare () {
  LATEST_PKGVER=$(curl -s https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=${1} 2>&1 | grep -Poi '^pkgver=(.*)$' | cut -d= -f2 | sed 's/"//g')
  LATEST_PKGREL=$(curl -s https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=${1} 2>&1 | grep -Poi '^pkgrel=(.*)$' | cut -d= -f2 | sed 's/"//g')

  BUILT_PKGVER=$(curl -s --fail https://aurbot.github.io/meta/${1}.pkgver)
  BUILT_PKGREL=$(curl -s --fail https://aurbot.github.io/meta/${1}.pkgrel)

  if [ "${LATEST_PKGVER}" = "${BUILT_PKGVER}" ] && [ "${LATEST_PKGREL}" = "${BUILT_PKGREL}" ]; then
    return true
  else
    false
  fi
}

if [ "${PACKAGE}" = "__compare__"]; then
  # start with empty matrix list
  cp .travis.yml.empty .travis.yml

  # add packages to matrix that are not up-to-date
  while read pkg do;
    if compare $pkg; then
      echo "    - PACKAGE=$pkg" >> .travis.yml
  done <packages

  # always add compare check to end of list
  echo "    - PACKAGE=__compare__" >> .travis.yml
  
  # commit new .travis.yml to repo to trigger new builds.
  git config user.name "${GITHUB_USER_NAME:-aurbot}"
  git config user.email "${GITHUB_USER_EMAIL:-aurbot@jankoppe.de}"
  git add .travis.yml
  git commit -m "aurbot added out-of-date packages to .travis.yml"
  git push
  exit 0
fi