# encoding: utf-8
require 'base64'
require 'net/http'
require 'open-uri'

module CMDB
  class Source::Consul < Source::Network
    # Regular expression to match array values
    ARRAY_VALUE = /^\[(.*)\]$/

    # Get a single key from consul
    # @param [String] key dot-notation key
    def get(key)
      key = dot_to_slash(key)
      response = http_get path_to(key)
      case response
      when Array
        item = response.first
        load_value(Base64.decode64(item['Value']))
      when 404
        nil
      else
        raise CMDB:Error.new("Unexpected consul response #{value.inspect}")
      end
    end

    # Set a single key in consul.
    # @param [String] key dot-notation key
    def set(key, value)
      key = dot_to_slash(key)
      http_put path_to(key), value
    end

    # Iterate through all keys in this source.
    # @return [Integer] number of key/value pairs that were yielded
    def each_pair(&_block)
      path = path_to('/')
      all = http_get path, query:'recurse'
      unless all.is_a?(Array)
        raise CMDB::Error.new("Unexpected consul response to 'GET #{path}': #{all.inspect}")
      end

      all.each do |item|
        dotted_prefix = (@preix && @prefix.split('/').join('.')) || ''
        dotted_key = item['Key'].split('/').join('.')
        key = dotted_prefix == '' ? dotted_key : dotted_key.split("#{dotted_prefix}.").last
        value = load_value(Base64.decode64(item['Value']))
        yield(key, value)
      end

      all.size
    end

    # Test connectivity to consul agent.
    #
    # @return [Boolean]
    def ping
      http_get('/') == 'Consul Agent'
    rescue
      false
    end

    private

    # Given a key's relative path, return its absolute REST path in the consul
    # kv, including any prefix that was specified at startup.
    def path_to(subkey)
      p = '/v1/kv/'
      (p << prefix << '/') unless prefix.nil?
      p << subkey unless (subkey == '/' && p[-1] == '/')
      p
    end
  end
end
