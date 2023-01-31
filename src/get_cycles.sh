#!/bin/sh
cat /dev/stdin | grep -Eio "total cycles = ([0-9]+)" | grep -Eo "([0-9]+)"
