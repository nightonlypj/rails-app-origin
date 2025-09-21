FROM nginx:1.27.5-alpine
RUN apk add --no-cache gettext

COPY ecs/web/nginx/nginx.conf.template /etc/nginx/
COPY ecs/web/nginx/conf.d/default.conf.template /etc/nginx/conf.d/
COPY public/_check /usr/share/nginx/html/

# Add a script to be executed every time the container starts.
COPY ecs/web/entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

# Configure the main process to run when running the image
CMD ["nginx", "-g", "daemon off;"]
