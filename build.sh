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

export LATEST_PKGVER=$(curl -s https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=${PACKAGE} 2>&1 | grep -Poi '^pkgver=(.*)$' | cut -d= -f2 | sed 's/"//g')
export LATEST_PKGREL=$(curl -s https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=${PACKAGE} 2>&1 | grep -Poi '^pkgrel=(.*)$' | cut -d= -f2 | sed 's/"//g')
export BUILT_PKGVER=$(curl -s --fail https://aurbot.github.io/meta/${PACKAGE}.pkgver)
export BUILT_PKGREL=$(curl -s --fail https://aurbot.github.io/meta/${PACKAGE}.pkgrel)

echo "I have ${PACKAGE} version ${BUILT_PKGVER}-${BUILT_PKGREL} and now will build ${LATEST_PKGVER}-${LATEST_PKGREL}"

# build package and put into repository directory
mkdir -p aurbot
docker pull jankoppe/arch-aurbuild
docker run -it \
  -v $(pwd)/aurbot:/home/arch/out \
  --entrypoint sh \
  jankoppe/arch-aurbuild \
  -c "sudo pacman -Sy; pacaur -S --check --noconfirm --noedit $PACKAGE"
docker inspect $(docker ps -aq)

if [ $? -ne 0 ]; then
  echo "aurbot failed building $PACKAGE."
  exit $?
fi

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
