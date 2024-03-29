#!/bin/bash
#    aurbot - automated arch linux user repository package builder
#    Copyright (C) 2017  J. Koppe
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Compare lates and built version for each package and generate a new .travis.yml with updated matrix from that.

compare () {
  LATEST_PKGVER=$(curl -s https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=${1} 2>&1 | grep -Poi '^pkgver=(.*)$' | cut -d= -f2 | sed 's/"//g')
  LATEST_PKGREL=$(curl -s https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=${1} 2>&1 | grep -Poi '^pkgrel=(.*)$' | cut -d= -f2 | sed 's/"//g')

  BUILT_PKGVER=$(curl -s --fail https://aurbot.github.io/meta/${1}.pkgver)
  BUILT_PKGREL=$(curl -s --fail https://aurbot.github.io/meta/${1}.pkgrel)

  if [ "${LATEST_PKGVER}" = "${BUILT_PKGVER}" ] && [ "${LATEST_PKGREL}" = "${BUILT_PKGREL}" ]; then
    echo "${1} latest is ${LATEST_PKGVER}-${LATEST_PKGREL}, have ${BUILT_PKGVER}-${BUILT_PKGREL}. All okay."
    return 0
  else
    echo "${1} latest is ${LATEST_PKGVER}-${LATEST_PKGREL}, have ${BUILT_PKGVER}-${BUILT_PKGREL}. Needs rebuild."
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
