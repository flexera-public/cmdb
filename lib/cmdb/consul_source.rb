# encoding: utf-8
require 'diplomat'

module CMDB
  class ConsulSource
    # Regular expression to match array values
    ARRAY_VALUE = /^\[(.*)\]$/

    ### Class variables

    class << self
      attr_writer :url
    end

    class << self
      attr_reader :url
    end

    class << self
      attr_writer :prefixes
    end

    class << self
      attr_reader :prefixes
    end

    ### Instance variables

    # The url to communicate with consul
    @url = nil

    # Initialize the configuration for consul source
    def initialize(prefix)
      Diplomat.configure do |config|
        config.url = self.class.url
      end
      @prefix = prefix
    end

    # Get a single key from consul
    def get(key)
      value = Diplomat::Kv.get(dot_to_slash(key))
      process_value(value)
    rescue TypeError
      puts 'hi'
    rescue Diplomat::KeyNotFound
      nil
    end

    # Iterate through all keys with a given prefix in consul
    def each_pair(&_block)
      prefix = @prefix || ''
      all = Diplomat::Kv.get(prefix, recurse: true)
      all.each do |item|
        dotted_prefix = prefix.split('/').join('.')
        dotted_key = item[:key].split('/').join('.')
        key = dotted_prefix == '' ? dotted_key : dotted_key.split("#{dotted_prefix}.").last
        value = process_value(item[:value])
        yield(key, value)
      end
    rescue Diplomat::KeyNotFound => exc
      CMDB.log.warn exc.message
    end

    private

    # Lazily parse a value, which may be valid JSON or may be a bare string.
    # TODO: concat a regexp to match JSONable things
    def process_value(val)
      JSON.load(val)
    rescue JSON::ParserError
      val
    end

    # Converts the dotted notation to a slashed notation. If a @prefix is set, it applies the prefix.
    # @example
    #   "common.proxy.endpoints" => common/proxy/endpoints (or) shard403/common/proxy/endpoints
    def dot_to_slash(key)
      key = "#{@prefix}.#{key}" unless @prefix.nil?
      key.split('.').join('/')
    end
  end
end
