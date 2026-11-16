#!/bin/sh
set -eu
port="${PORT:-10000}"
case "$port" in ''|*[!0-9]*) echo "Invalid PORT" >&2; exit 1 ;; esac
if [ "$port" -lt 1024 ] || [ "$port" -gt 65535 ]; then echo "PORT out of range" >&2; exit 1; fi
# The standard Tomcat server.xml includes a connector listening on port 8080.
sed -i "s/port=\"8080\"/port=\"${port}\"/" "$CATALINA_HOME/conf/server.xml"
exec "$CATALINA_HOME/bin/catalina.sh" run
