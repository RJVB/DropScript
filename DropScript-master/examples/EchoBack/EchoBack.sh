#!/bin/sh

if [ $# != 0 ] ;then
	/usr/local/bin/echo -n "$0 called with arguments " > /tmp/t.txt;
	for a in "$@" ;do
		/usr/local/bin/echo -n " \"$a\"" >> /tmp/t.txt
	done
else
	/usr/local/bin/echo "$0 called without arguments " > /tmp/t.txt;
fi
open /tmp/t.txt
