#! /bin/bash

PROACTIVE_LIB="../../../../lib/ProActive"

echo compiling the Java source files...
cd ./client/out
rm -r ./client/out
cp -r larva ./client
cp -r ppArtifacts ./client

mkdir clientbuild
javac -cp ./:$PROACTIVE_LIB/log4j-1.2.17.jar:$PROACTIVE_LIB/ProActive.jar -target 1.8 $(find ./client -name '*.java') -d ./clientbuild

echo compiling AspectJ files...
~/aspectj1.8/bin/ajc -1.8 -cp ../../aspectjrt.jar:$PROACTIVE_LIB/log4j-1.2.17.jar:$PROACTIVE_LIB/ProActive.jar -sourceroots ./clientbuild

echo weaving aspects into the JAR...
cp -r aspects ./clientbuild
~/aspectj1.8/bin/ajc -1.8 -cp ../../aspectjrt.jar:./clientbuild:$PROACTIVE_LIB/log4j-1.2.17.jar:$PROACTIVE_LIB/ProActive.jar -outxmlfile ./clientbuild/META-INF/aop.xml ./clientbuild/aspects/*.aj

echo compilation done!
