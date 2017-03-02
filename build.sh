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

# Let's clone the current state of the aurbot.github.io repository, so we can add & push the package.
# Set up git lfs before we do anything, so that we don't blow up our repo size.
git clone --depth 1 --branch master "https://${GITHUB_TOKEN}@${GITHUB_REF:-github.com/aurbot/aurbot.github.io}" gitrepo
cd gitrepo
git config user.name "${GITHUB_USER_NAME:-aurbot}"
git config user.email "${GITHUB_USER_EMAIL:-aurbot@jankoppe.de}"
git lfs track '*.tar.gz'
git lfs track 'aurbot.*'
git lfs track
git add .gitattributes

# build package and put into repository directory
mkdir -p aurbot
docker run -it --rm -v $(pwd)/aurbot:/home/arch/out jankoppe/arch-aurbuild ${PACKAGE}

# rebuild repository index
set +e
rm aurbot/aurbot.{db,files}*
set -e

docker run -it --rm -v $(pwd)/aurbot:/out -v $(pwd)/aurbot:/aurbot jankoppe/arch sh -c 'for pkg in /aurbot/*; do repo-add /aurbot/aurbot.db.tar.gz $pkg; done'

# update version metadata
mkdir -p meta

echo "${LATEST_PKGVER}" > meta/${PACKAGE}.pkgver
echo "${LATEST_PKGREL}" > meta/${PACKAGE}.pkgrel

# add all files to repo
git add meta aurbot
git commit -m "aurbot built ${PACKAGE}-${LATEST_PKGVER}-${LATEST_PKGREL}"

git push