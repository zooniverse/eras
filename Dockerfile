FROM ruby:3.2-buster
WORKDIR /app
ARG RAILS_ENV

RUN apt-get update && \
  apt-get install --no-install-recommends -y git curl libpq-dev libjemalloc2 && \
  apt-get clean && rm -rf /var/lib/apt/lists/*

ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2

ADD ./Gemfile /app/
ADD ./Gemfile.lock /app/

RUN if [ "$RAILS_ENV" = "development" ]; then bundle install; else bundle install --without development test; fi

ADD ./ /app

RUN (cd /app && mkdir -p tmp/pids)

CMD [ "bundle", "exec", "puma", "config.ru"]
