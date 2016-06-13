require 'redis'
require 'hiredis'

opts = {}
opts[:host] = ENV.fetch('REDIS_PORT_6379_TCP_ADDR', 'redis')
opts[:port] = ENV.fetch('REDIS_PORT_6379_TCP_PORT', 6379)
opts[:driver] = :hiredis

$redis = Redis.new(opts)
