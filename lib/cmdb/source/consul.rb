# encoding: utf-8
require 'base64'
require 'net/http'
require 'open-uri'

module CMDB
  class Source::Consul < Source::Network
    # Regular expression to match array values
    ARRAY_VALUE = /^\[(.*)\]$/

    def initialize(uri, prefix)
      super(uri, 8500, prefix)
      useless = uri.path.split('/')
      useless.shift ; useless.pop # del initial "" and final word (aka prefix)
      @useless = CMDB.join(useless)
    end

    # Get a single key from consul. If the key is not found, return nil.
    #
    # @param [String] key dot-notation key
    # @return [Object]
    def get(key)
      return nil unless prefixed?(key)
      key = dot_to_slash(key)
      response = http_get path_to(key)
      case response
      when String
        response = json_parse(response)
        item = response.first
        item['Value'] && json_parse(Base64.decode64(item['Value']))
      when 404
        nil
      else
        raise CMDB::Error.new("Unexpected consul response #{response.inspect}")
      end
    end

    # Set a single key in consul. If value is nil, then delete the key
    # entirely from consul. If this source cannot accept the write due to
    # key name limitations, return nil.
    #
    # @return [true,nil]
    # @param [String] key dot-notation key
    # @param [Object] value new value of key
    # @raise [CMDB:Error] if the write fails atthe consul server
    def set(key, value)
      return nil unless prefixed?(key)
      key = dot_to_slash(key)
      if value.nil?
        status = http_delete path_to(key)
      else
        status = http_put path_to(key), value
      end

      if status >= 200 && status < 300
        true
      else
        raise CMDB::Error.new("Consul put/delete failed with status #{status}")
      end
    end

    # Iterate through all keys in this source.
    # @return [Integer] number of key/value pairs that were yielded
    def each_pair(&_block)
      path = path_to('/')

      case result = http_get(path, query:'recurse')
      when String
        result = json_parse(result)
      when 404
        return # no keys!
      end

      unless result.is_a?(Array)
        raise CMDB::Error.new("Consul 'GET #{path}': expected Array, got #{all.class.name}")
      end

      result.each do |item|
        key = slash_to_dot(item['Key'])
        key.sub(@useless,'')
        next unless item['Value']
        value = json_parse(Base64.decode64(item['Value']))
        yield(key, value)
      end

      result.size
    end

    # Test connectivity to consul agent.
    #
    # @return [Boolean]
    def ping
      http_get('/') == 'Consul Agent'
    rescue
      false
    end

    # Given a key's relative path, return its absolute REST path in the consul
    # kv, including the `/v1/kv/` prefix and any subkey path specified at
    # initialize time.
    #
    # @param [String] subpath key path relative to base
    def path_to(subpath)
      ::File.join('/v1/kv/', @uri.path, subpath)
    end

    # Transform a subpath into a key name. Account for base-path prefix if
    # necessary.
    def slash_to_dot(path)
      dot = super
      dot.sub!(@useless,'')
      dot=dot[1..-1] if dot[0] == '.'
      dot
    end
  end
end
