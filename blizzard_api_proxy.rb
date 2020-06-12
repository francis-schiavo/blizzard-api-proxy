# frozen_string_literal: true

require 'sinatra'
require 'sinatra/cors'
require 'blizzard_api'
require 'thread'

COMMON_OPTIONS = %w[locale classic ignore_cache ttl]

set :bind, '0.0.0.0'
set :allow_origin, ENV.fetch('CORS_ORIGIN', '*')
use Rack::Deflater

BlizzardApi.configure do |config|
  config.region = ENV.fetch 'REGION', 'us'
  config.app_id = ENV.fetch 'BNET_APPLICATION_ID'
  config.app_secret = ENV.fetch 'BNET_APPLICATION_SECRET'

  if ENV.fetch('USE_CACHE', 'false') == 'true'
    config.use_cache = true
    config.redis_host = ENV.fetch 'REDIS_HOST', ''
    config.redis_port = ENV.fetch 'REDIS_PORT', ''
  end
end

before do
  content_type :json
  @region = BlizzardApi.region
  @region = @request.params['region'] if @request.params.key? 'region'
  @options = {}
  @request.params.each do |key, value|
    next unless COMMON_OPTIONS.include? key

    if %w[classic ignore_cache].include? :key
      @options[key.to_sym] = !!value
    elsif key.eql? 'ttl'
      @options[key.to_sym] = value.to_i
    else
      @options[key.to_sym] = value
    end
  end
end

not_found do
  { status: 'Not found' }.to_json
end

get '/' do
  { status: 'Running' }.to_json
end

require_relative 'api/token_map'
require_relative 'api/hs'
require_relative 'api/wow'
require_relative 'api/d3'
require_relative 'api/sc2'
require_relative 'api/oauth'

error BlizzardApi::ApiException do |e|
  status e.code
  { error: e.message }.to_json
end