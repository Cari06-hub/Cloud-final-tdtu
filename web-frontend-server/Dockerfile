FROM nginx:stable
RUN rm -f /etc/nginx/conf.d/default.conf
COPY conf.default /etc/nginx/conf.d/default.conf
COPY html/ /usr/share/nginx/html/
# Prometheus exposition format must use LF even when the source was checked out
# with CRLF on Windows.
RUN sed -i 's/\r$//' /usr/share/nginx/html/metrics \
    && chmod -R 755 /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
