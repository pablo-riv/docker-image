#!/bin/sh

set -e

service nginx stop
service nginx reload
service nginx start
service nginx status

if [ ! -z $CRON_RUN ]; then
  echo "**********UPDATING CRONTAB WITH WHENEVER************"
  apt-get update && \
    apt-get -y install cron rsyslog > /dev/null
  service cron start && service rsyslog start
  bundle exec whenever --update-crontab

  mkdir log && touch log/whenever.log
  bundle exec puma -C config/puma.rb && \
    tail -f log/whenever.log /var/log/syslog >> /proc/1/fd/1
else
  echo "**********Starting sneakers CLIENTES************"
  bundle exec rake sneakers:run

  echo "**********Starting sidekiq CLIENTES************"
  bundle exec sidekiq -L log/sidekiq.log -C config/sidekiq.yml -d

  echo "**********Starting CLIENTES APP on port 5080************"
  bundle exec puma -C config/puma.rb -e production && \
    tail -fq log/production.log log/workers.log* log/sidekiq.log /tmp/log/nginx.error.log /tmp/log/nginx.access.log >> /proc/1/fd/1
fi
