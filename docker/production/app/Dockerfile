FROM 090358380644.dkr.ecr.us-west-2.amazonaws.com/base:2.3.7

# NODE
RUN apt-get update; \
    apt-get install -y curl gnupg; \
    curl -sL https://deb.nodesource.com/setup_10.x | bash -; \
    apt-get install -y nodejs; \
    npm install -g mjml@4.3.1; \
    rm -rf /var/lib/apt/lists/*

# APP
WORKDIR /usr/src/app
ADD ./ ./
RUN bundle install

# ENTRYPOINT AND EXPOSE PORT
COPY docker/production/app/prod.sh ./prod.sh
RUN chmod +x ./prod.sh
ENTRYPOINT [ "./prod.sh" ]
EXPOSE 5080
