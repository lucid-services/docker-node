FROM node:current-alpine

WORKDIR /

RUN apk update  \
&&  apk upgrade \
&&  apk add --no-cache --virtual build-deps g++ make perl-dev tzdata \
&&  cp /usr/share/zoneinfo/UTC /etc/localtime \
&&  echo UTC > /etc/timezone \
#required by ./wait-for-it.sh && sqitch
&&  apk add --no-cache bash perl \
#https://github.com/sqitchers/sqitch
&&  cpan DateTime IPC::System::Simple App::Sqitch \
&&  apk del build-deps

COPY . .
