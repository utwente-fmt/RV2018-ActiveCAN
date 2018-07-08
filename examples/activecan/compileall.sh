#! /bin/bash

./starvoors.sh monitor
./starvoors.sh client1
./starvoors.sh client2

./compile.sh monitor
./compile.sh client1
./compile.sh client2
