#! /bin/bash

PROACTIVE_LIB="../../lib/ProActive"

java -cp ./build:$PROACTIVE_LIB/log4j-1.2.17.jar:$PROACTIVE_LIB/ProActive.jar:$PROACTIVE_LIB/slf4j-api-1.7.12.jar:$PROACTIVE_LIB/slf4j-jdk14-1.7.25.jar -Djava.security.policy=$PROACTIVE_LIB/config/proactive.java.policy -Dlog4j.configuration=file:$PROACTIVE_LIB/config/proactive-log4j Server
