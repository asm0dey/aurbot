#!/bin/bash
set -v
mkdir -p out
mkdir -p report
mkdir -p repo

echo "failed:" > report/failed.yml
echo "built:" > report/built.yml

docker run -it --rm -v $(pwd)/out:/home/arch/out jankoppe/arch-aurbuild $PACKAGE

if [ $? -ne 0 ]; then
  echo "  - $PACKAGE" >> report/failed.yml
else
  echo "  - $PACKAGE" >> report/built.yml
fi


for artefact in out/*; do
  docker run -it --rm -v $(pwd)/out:/out -v $(pwd)/repo:/repo jankoppe/arch repo-add /repo/aurbot.db.tar.gz /out/$artefact
done

mv out/* repo

rm -r out
