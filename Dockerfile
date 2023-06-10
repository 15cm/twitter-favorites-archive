FROM ruby:3.2-buster

RUN apt-get update \
    && apt-get install -y cron jq fd-find parallel exiftool locales locales-all \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s /usr/bin/fdfind /usr/bin/fd \
    && locale-gen en_US.UTF-8
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

# s6-overlay
ADD https://github.com/just-containers/s6-overlay/releases/download/v1.22.1.0/s6-overlay-amd64.tar.gz /tmp/
RUN tar xzf /tmp/s6-overlay-amd64.tar.gz -C /

# Project setup
WORKDIR /app
COPY Gemfile* ./
RUN gem install bundler && bundle install
COPY src ./src
COPY scripts ./scripts

# s6 setup
COPY docker/root /

ENV FAVORITES_NUMBER_TO_FETCH=0

VOLUME ["/app/output"]
ENTRYPOINT ["/init"]
