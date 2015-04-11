FROM ruby:2.2

RUN mkdir -p /src
WORKDIR /src
COPY . /src

RUN gem install bundler
RUN bundle install
