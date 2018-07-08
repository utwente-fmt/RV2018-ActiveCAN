#! /bin/bash

if [ -z "$1" ]
then
	echo 'provide a destination directory'
	exit 1
fi

BUILD_PATH="./build/$1"

rm -r $BUILD_PATH
mkdir $BUILD_PATH

echo running StaRVOOrS to generate the DATE monitors...
../../dist/build/StaRVOOrS-tool/StaRVOOrS-tool ./ ./client.ppd $BUILD_PATH -r -d

rm -r $BUILD_PATH/out/build
mkdir $BUILD_PATH/out/build
