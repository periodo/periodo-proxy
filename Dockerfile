FROM --platform=linux/amd64 nginx

COPY nginx.conf /etc/nginx/conf.d/default.conf

RUN mkdir /srv/www
RUN mkdir /srv/www/client_packages

COPY vocab.ttl /srv/www/vocab.ttl
COPY vocab.html /srv/www/vocab.html
COPY highlight-style.css /srv/www/highlight-style.css

RUN chown -R nginx /srv/www

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    python3-full \
    && rm -rf /var/lib/apt/lists/*
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

COPY cache-purger.py /cache-purger.py

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
