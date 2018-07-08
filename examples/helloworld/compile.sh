#! /bin/bash

PROACTIVE_LIB="../../lib/ProActive"

echo compiling Java files...
javac -cp $PROACTIVE_LIB/log4j-1.2.17.jar:$PROACTIVE_LIB/ProActive.jar -d ./build ./lib/Hello.java Client.java Server.java

echo compilation done!