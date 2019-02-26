#!/bin/sh
cd ${0%/*} || exit 1    # run from this directory

rm slurm.*
# Source tutorial run functions
. $WM_PROJECT_DIR/bin/tools/CleanFunctions

cd ./simpleFoam
cleanCase
