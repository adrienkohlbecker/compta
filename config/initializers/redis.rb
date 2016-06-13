# frozen_string_literal: true
require 'redis'
require 'hiredis'

REDIS_OPTS = {
  host: ENV.fetch('REDIS_PORT_6379_TCP_ADDR', 'redis'),
  port: ENV.fetch('REDIS_PORT_6379_TCP_PORT', 6379),
  driver: :hiredis
}.freeze
