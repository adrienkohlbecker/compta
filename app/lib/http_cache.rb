# frozen_string_literal: true
require 'httparty'
require 'digest/md5'

class HTTPCache
  class << self
    def redis
      @redis ||= Redis.new(REDIS_OPTS)
    end
  end

  def initialize(uri, key: :default, expires_in: 3600)
    @uri = uri
    @key = key
    @expires_in = expires_in
  end

  def cached?
    HTTPCache.redis.exists(cache_key_name)
  end

  def get
    if cached?
      Rails.logger.info "[HTTPCache] Using cache for #{@uri}"
      return response_body_from_cache
    else
      response = fetch_response
      if response.code != 200
        raise "HTTP Error #{response.code} fetching #{@uri}"
      else
        Rails.logger.info "[HTTPCache] Fetching #{@uri}"
        store_in_cache(response.body)
        return response.body
      end
    end
  end

  def flush_cache
    HTTPCache.redis.del(cache_key_name)
  end

  private def fetch_response
    HTTParty.get(@uri, headers: { 'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2272.43 Safari/537.36' })
  end

  private def cache_key_name
    uri_hash = Digest::MD5.hexdigest(@uri)
    "httpcache:#{@key}:#{uri_hash}"
  end

  private def response_body_from_cache
    HTTPCache.redis.get(cache_key_name)
  end

  private def store_in_cache(response_body)
    HTTPCache.redis.set(cache_key_name, response_body)
    HTTPCache.redis.expire(cache_key_name, @expires_in)
  end
end
