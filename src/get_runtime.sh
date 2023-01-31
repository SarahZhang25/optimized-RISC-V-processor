#!/bin/sh
cat /dev/stdin | grep -Eio "Runtime = ([0-9]+)" | grep -Eo "([0-9]+)"
