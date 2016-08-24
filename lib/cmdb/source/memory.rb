# encoding: utf-8
require 'uri'

module CMDB
  # Data source that is backed by the an in-memory Ruby hash; used solely for
  # testing.
  class Source::Memory
    # @return [String] the empty string
    attr_reader :prefix

    # Construct a new Source::Memory.
    def initialize(hash, prefix)
      uri = URI.parse("memory:#{hash.object_id}")
      super(uri, prefix)
      @hash = hash
    end

    # Get the value of key.
    #
    # @return [nil,String,Numeric,TrueClass,FalseClass,Array] the key's value, or nil if not found
    def get(key)
      @hash[key]
    end

    # Set the value of a key.
    def set(key, value)
      value = JSON.dump(value) unless value.is_a?(String)
      @hash[key] = value
    end

    # Enumerate the keys in this source, and their values.
    #
    # @yield every key/value in the source
    # @yieldparam [String] name of key
    # @yieldparam [Object] value of key
    def each_pair(&block)
      @hash.each_pair(&block)
    end
  end
end
