FROM ruby:2.3.7
RUN apt-get update -qq && apt-get install -y libpq-dev postgresql-client git-core curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev
RUN apt-get install -y libxml2-dev libxslt1-dev libcurl4-openssl-dev software-properties-common libffi-dev dirmngr gnupg apt-transport-https ca-certificates redis-server redis-tools nodejs yarn

ENV RAILS_ROOT /orders
RUN mkdir $RAILS_ROOT
WORKDIR $RAILS_ROOT

ENV RAILS_ENV=development
ENV RACK_ENV=development

COPY Gemfile $RAILS_ROOT/Gemfile
COPY Gemfile.lock $RAILS_ROOT/Gemfile.lock

RUN bundle install --jobs 20 --retry 5
COPY . $RAILS_ROOT

# Add a script to be executed every time the container starts.
COPY docker/app/entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
EXPOSE 3000
