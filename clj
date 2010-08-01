#!/bin/sh
CLOJURE_LIB=~/Library/Clojure/lib
CLASSPATH=$CLOJURE_LIB/clojure-1.2.0-RC1.jar:$CLOJURE_LIB/clojure-contrib-1.2.0-RC1.jar:$CLOJURE_LIB/jline-0.9.94.jar

java -Xmx3G -cp $CLASSPATH jline.ConsoleRunner clojure.main $@

# -agentlib:yjpagent 
