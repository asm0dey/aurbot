#!/bin/bash

#not really necessary, but be sure.
if [ "${PACKAGE}" = "__compare__" ]; then
  exit 0
fi


# Let's clone the current state of the aurbot.github.io repository, so we can add & push the package.
# Set up git lfs before we do anything, so that we don't blow up our repo size. !!! git lfs does not work with github pages, skip for now.
git clone --depth 1 --branch master "https://${GITHUB_TOKEN}@${GITHUB_REF:-github.com/aurbot/aurbot.github.io}" gitrepo
cd gitrepo
git config user.name "${GITHUB_USER_NAME:-aurbot}"
git config user.email "${GITHUB_USER_EMAIL:-aurbot@jankoppe.de}"
#git lfs track '*.tar.gz'
#git lfs track '*.tar.xz'
#git lfs track 'aurbot.*'
#git lfs track
#git add .gitattributes

LATEST_PKGVER=$(curl -s https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=${1} 2>&1 | grep -Poi '^pkgver=(.*)$' | cut -d= -f2 | sed 's/"//g')
LATEST_PKGREL=$(curl -s https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=${1} 2>&1 | grep -Poi '^pkgrel=(.*)$' | cut -d= -f2 | sed 's/"//g')
BUILT_PKGVER=$(curl -s --fail https://aurbot.github.io/meta/${PACKAGE}.pkgver)
BUILT_PKGREL=$(curl -s --fail https://aurbot.github.io/meta/${PACKAGE}.pkgrel)

# build package and put into repository directory
mkdir -p aurbot
docker run -it --rm\
  -v $(pwd)/aurbot:/home/arch/out\
  -v $(pwd)/aurbot_repo.conf:/etc/pacman.d/aurbot_repo.conf\
  --entrypoint sh\
  jankoppe/arch-aurbuild\
  -c "sudo pacman -Sy; pacaur -Sm --noconfirm --noedit $PACKAGE"

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