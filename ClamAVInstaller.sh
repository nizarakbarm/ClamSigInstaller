#!/bin/bash

latestlts_release=$(curl -s -A @ua https://www.clamav.net/downloads -L | grep '<span class="badge">LTS</span>' | hxselect -c -s "\n" "h4" | grep -oE "[[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+" | head -n 1)