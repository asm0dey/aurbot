#!/bin/bash

mkdir -p out

for package in $(cat packages); do
  docker -it --rm -v $(pwd)/out:/home/arch/out jankoppe/arch-aurbuild $package
done