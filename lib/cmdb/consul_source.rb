require 'diplomat'

module CMDB
  class ConsulSource
    # Regular expression to match array values
    ARRAY_VALUE = /^\[(.*)\]$/

    # The url to communicate with consul
    @@url = nil
    # The prefixes to use when getting keys from consul
    @@prefixes = nil

    def self.url=(url)
      @@url = url
    end

    def self.url
      @@url
    end

    def self.prefixes=(prefixes)
      @@prefixes = prefixes
    end

    def self.prefixes
      @@prefixes
    end

    # Initialize the configuration for consul source
    def initialize(prefix)
      Diplomat.configure do |config|
        config.url = @@url
      end
      @prefix = prefix
    end

    # Get a single key from consul
    def get(key)
      value = Diplomat::Kv.get(dot_to_slash(key))
      process_value(value)
    rescue Diplomat::KeyNotFound
      nil
    end

    # Not implemented for consul source
    def each_pair(&block)
      prefix = @prefix || ''
      all = Diplomat::Kv.get(prefix, recurse: true)
      all.each do |item|
        dotted_prefix = prefix.split('/').join('.')
        dotted_key = item[:key].split('/').join('.')
        key = dotted_prefix == '' ? dotted_key : dotted_key.split("#{dotted_prefix}.").last
        value = process_value(item[:value])
        block.call(key, value)
      end
    rescue Diplomat::KeyNotFound
    end

    private

    def process_value(val)
      return JSON.load(val)
    rescue Exception
      return val
    end

    # Converts the dotted notation to a slashed notation. If a @@prefix is set, it applies the prefix.
    # @example
    #   "common.proxy.endpoints" => common/proxy/endpoints (or) shard403/common/proxy/endpoints
    def dot_to_slash(key)
      key = "#{@prefix}.#{key}" unless @prefix.nil?
      key.split('.').join('/')
    end
  end
end

