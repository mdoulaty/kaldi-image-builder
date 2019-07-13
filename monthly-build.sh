#!/bin/bash

tag=$(date +%Y-%m)  # e.g. 2019-07
echo "Starting build with tag $tag ..."

make clean 
make tag=$tag cpu &
make tag=$tag gpu &

echo "Waiting for the builds to finish..."
wait

echo "Cleaning up resources..."
make clean

echo "All done."

