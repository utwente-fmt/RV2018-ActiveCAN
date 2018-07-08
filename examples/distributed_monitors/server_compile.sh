#! /bin/bash

PROACTIVE_LIB="../../../../lib/ProActive"

echo compiling the Java source files...
cd ./server/out
rm -r ./server/out
cp -r larva ./server
cp -r ppArtifacts ./server

mkdir serverbuild
javac -cp ./:$PROACTIVE_LIB/log4j-1.2.17.jar:$PROACTIVE_LIB/ProActive.jar -target 1.8 $(find ./server -name '*.java') -d ./serverbuild

echo compiling AspectJ files...
~/aspectj1.8/bin/ajc -1.8 -cp ../../aspectjrt.jar:$PROACTIVE_LIB/log4j-1.2.17.jar:$PROACTIVE_LIB/ProActive.jar -sourceroots ./serverbuild

echo weaving aspects into the JAR...
cp -r aspects ./serverbuild
~/aspectj1.8/bin/ajc -1.8 -cp ../../aspectjrt.jar:./serverbuild:$PROACTIVE_LIB/log4j-1.2.17.jar:$PROACTIVE_LIB/ProActive.jar -outxmlfile ./serverbuild/META-INF/aop.xml ./serverbuild/aspects/*.aj

echo compilation done!
