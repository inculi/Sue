#!/bin/bash

for x in $(sue_signal/signal-cli/build/install/signal-cli/bin/signal-cli -u +12079560670 listIdentities | grep -i UNTRUSTED | awk -F: '{print $1}')
do
	sue_signal/signal-cli/build/install/signal-cli/bin/signal-cli -u +12079560670 trust -a $x
done
