FROM ruby:2.2.1

WORKDIR /tmp
ADD Gemfile /tmp/Gemfile
ADD Gemfile.lock /tmp/Gemfile.lock
RUN bundle install

WORKDIR /app/compta
ADD . /app/compta
