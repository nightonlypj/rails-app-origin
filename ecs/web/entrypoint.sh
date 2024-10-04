#!/bin/sh
set -e

if [ "$NGINX_WORKER_PROCESSES" = '' ]; then
    export NGINX_WORKER_PROCESSES="auto" # 最大値: vCPUの数 or auto = 16と仮定して
    echo "NGINX_WORKER_PROCESSES: $NGINX_WORKER_PROCESSES(default)"
else
    echo "NGINX_WORKER_PROCESSES: $NGINX_WORKER_PROCESSES"
fi
if [ "$NGINX_WORKER_RLIMIT_NOFILE" = '' ]; then
    export NGINX_WORKER_RLIMIT_NOFILE=32768 # 最大値: 524288(cat /proc/sys/fs/file-max) / NGINX_WORKER_PROCESSES
    echo "NGINX_WORKER_RLIMIT_NOFILE: $NGINX_WORKER_RLIMIT_NOFILE(default)"
else
    echo "NGINX_WORKER_RLIMIT_NOFILE: $NGINX_WORKER_RLIMIT_NOFILE"
fi
if [ "$NGINX_WORKER_CONNECTIONS" = '' ]; then
    export NGINX_WORKER_CONNECTIONS=8192 # 最大値: NGINX_WORKER_RLIMIT_NOFILE / 4
    echo "NGINX_WORKER_CONNECTIONS: $NGINX_WORKER_CONNECTIONS(default)"
else
    echo "NGINX_WORKER_CONNECTIONS: $NGINX_WORKER_CONNECTIONS"
fi
if [ "$NGINX_SET_REAL_IP_FROM" = '' ]; then
    export NGINX_SET_REAL_IP_FROM="172.31.0.0/16" # <- ELB
    echo "NGINX_SET_REAL_IP_FROM: $NGINX_SET_REAL_IP_FROM(default)"
else
    echo "NGINX_SET_REAL_IP_FROM: $NGINX_SET_REAL_IP_FROM"
fi
if [ "$NGINX_REAL_IP_HEADER" = '' ]; then
    export NGINX_REAL_IP_HEADER="X-Forwarded-For" # <- ELB
    echo "NGINX_REAL_IP_HEADER: $NGINX_REAL_IP_HEADER(default)"
else
    echo "NGINX_REAL_IP_HEADER: $NGINX_REAL_IP_HEADER"
fi
if [ "$NGINX_PROXY_PASS" = '' ]; then
    export NGINX_PROXY_PASS="http://unicorn_sock" # <- webapp, web: LBのURL
    echo "NGINX_PROXY_PASS: $NGINX_PROXY_PASS(default)"
else
    echo "NGINX_PROXY_PASS: $NGINX_PROXY_PASS"
fi

envsubst '$$NGINX_WORKER_PROCESSES $$NGINX_WORKER_RLIMIT_NOFILE $$NGINX_WORKER_CONNECTIONS $$NGINX_SET_REAL_IP_FROM $$NGINX_REAL_IP_HEADER' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf
envsubst '$$NGINX_PROXY_PASS' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf

# Then exec the container's main process (what's set as CMD in the Dockerfile).
exec "$@"
