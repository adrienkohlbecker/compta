FROM ruby:2.5

RUN gem install bundler -v 2.0.2

ADD Gemfile /tmp/Gemfile
ADD Gemfile.lock /tmp/Gemfile.lock
RUN (cd /tmp && bundle install)

WORKDIR /app
EXPOSE 3000

ADD . /app

CMD [ "bundle", "exec", "rails", "console"]
