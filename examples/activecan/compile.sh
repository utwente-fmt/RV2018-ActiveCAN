#! /bin/bash

if [ -z "$1" ]
then
	echo 'provide a destination directory'
	exit 1
fi

PROACTIVE_LIB="../../../../../lib/ProActive"

echo compiling the Java source files...
cd ./build/$1/out
rm -r ./build/$1/out
cp -r larva ./build
cp -r ppArtifacts ./build

echo compiling source files...
javac -cp ./:$PROACTIVE_LIB/log4j-1.2.17.jar:$PROACTIVE_LIB/ProActive.jar -target 1.8 $(find ./activecan -name '*.java') $(find ./monitoring -name '*.java') -d ./build

echo generating AspectJ files...
~/aspectj1.8/bin/ajc -1.8 -cp ../../../aspectjrt.jar:$PROACTIVE_LIB/log4j-1.2.17.jar:$PROACTIVE_LIB/ProActive.jar:./build -sourceroots ./build

echo weaving aspects into the JAR...
cp -r aspects ./build
~/aspectj1.8/bin/ajc -1.8 -cp ../../../aspectjrt.jar:./build:$PROACTIVE_LIB/log4j-1.2.17.jar:$PROACTIVE_LIB/ProActive.jar -outxmlfile ./build/META-INF/aop.xml ./build/aspects/*.aj

echo compilation done!
