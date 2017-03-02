#!/bin/bash

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