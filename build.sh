#!/bin/bash
set -v
mkdir -p out
mkdir -p report
mkdir -p repo

echo "failed:" > report/failed.yml
echo "built:" > report/built.yml

for package in $(cat packages); do
  docker run -it --rm -v $(pwd)/out:/home/arch/out jankoppe/arch-aurbuild $package
  if [ $? -ne 0 ]; then
    echo "  - $package" >> report/failed.yml
  else
    echo "  - $package" >> report/built.yml
  fi
done


for artefact in out/*; do
  docker run -it --rm -v $(pwd)/out:/out -v $(pwd)/repo:/repo jankoppe/arch repo-add /repo/aurbot.db.tar.gz /out/$artefact
done

mv out/* repo

rm -r out
