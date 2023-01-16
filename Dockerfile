FROM nginx:latest
COPY . /usr/share/nginx/html
ENTRYPOINT nginx -g 'daemon off;'
