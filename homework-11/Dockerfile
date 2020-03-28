FROM alpine:latest

LABEL maintainer="azat.r.garaev@[hidden].ru"

RUN apk update
RUN apk add --no-cache php7 php7-fpm

EXPOSE 9000

CMD ["php-fpm7", "-F"]
