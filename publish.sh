#!/bin/sh
# Version setzen (index.html + version.json gleich), damit installierte Apps «Neue Version» anzeigen
V=$(date -u +%Y-%m-%d.%H%M)
sed -i "s/^const APP_V='[^']*';/const APP_V='$V';/" index.html
printf '{"v":"%s"}\n' "$V" > version.json
echo "$V"
