#!/bin/bash
if ! pgrep -x "vino-server" > /dev/null
then
	export DISPLAY=:0
	/usr/lib/vino/vino-server &
fi
