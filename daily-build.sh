#!/bin/bash

echo "Starting daily build..."
make clean 
make cpu &
make gpu &

echo "Waiting for the builds to finish..."
wait

echo "Cleaning up resources..."
make clean

echo "All done."

