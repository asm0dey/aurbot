#!/bin/bash

# Before we do anything at all, let's first check if we even need to do a full build.
# This way, we can hopefully save a lot of travis resources.

LATEST_PKGVER=$(curl -s https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=${PACKAGE} 2>&1 | grep -Poi '^pkgver=(.*)$')
LATEST_PKGREL=$(curl -s https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=${PACKAGE} 2>&1 | grep -Poi '^pkgrel=(.*)$')

BUILT_PKGVER=$(curl -s --fail https://aurbot.github.io/meta/${PACKAGE}.pkgver)
BUILT_PKGREL=$(curl -s --fail https://aurbot.github.io/meta/${PACKAGE}.pkgrel)
set -e

if [ "${LATEST_PKGVER}" = "${BUILT_PKGVER}" ] && [ "${LATEST_PKGREL}" = "${BUILT_PKGREL}" ]; then
  echo ">>> package is already up to date, skip building."
  exit 0
else
  echo ">>> latest package is different from published, start build."
fi