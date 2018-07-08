#! /bin/bash

PROACTIVE_LIB="../../../../lib/ProActive"

echo compiling the Java source files...
cd ./build/out
rm -r ./build/out
cp -r larva ./main
cp -r ppArtifacts ./main

mkdir mainbuild
javac -cp ./:$PROACTIVE_LIB/log4j-1.2.17.jar:$PROACTIVE_LIB/ProActive.jar -target 1.8 $(find ./main -name '*.java') -d ./mainbuild

echo compiling AspectJ files...
~/aspectj1.8/bin/ajc -1.8 -cp ../../aspectjrt.jar -sourceroots ./mainbuild

echo weaving aspects into the JAR...
cp -r aspects ./mainbuild
~/aspectj1.8/bin/ajc -1.8 -cp ../../aspectjrt.jar:./mainbuild -outxmlfile ./mainbuild/META-INF/aop.xml ./mainbuild/aspects/*.aj

echo compilation done!