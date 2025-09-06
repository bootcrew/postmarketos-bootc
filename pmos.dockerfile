FROM alpine:edge
COPY repositories /etc/apk/repositories
RUN wget https://mirror.postmarketos.org/build.postmarketos.org.rsa.pub -O /etc/apk/keys/build.postmarketos.org.rsa.pub
RUN apk upgrade --no-cache -Ua
RUN apk add -U --no-cache postmarketos-base-systemd postmarketos-ui-console && apk upgrade --no-cache -Ua
