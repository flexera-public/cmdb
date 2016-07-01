# encoding: utf-8
require 'uri'

module CMDB
  # Data source that is backed by the process environment. Keys are natively
  # represented as UPPER_CASE_UNDERSCORE and all dotted keys are coerced to
  # native form before get/set.
  class EnvironmentSource
    # @return [String] the empty string
    def prefix
      ''
    end

    # Construct a new EnvironmentSource.
    def initialize(hash=ENV)
      @env = hash
    end

    # Get the value of key.
    #
    # @return [nil,String,Numeric,TrueClass,FalseClass,Array] the key's value, or nil if not found
    def get(key)
      @env[dot_to_env(key)]
    end

    # Set the value of a key.
    def set(key, value)
      value = JSON.dump(value) unless value.is_a?(String)
      @env[dot_to_env(key)] = value
    end

    # Enumerate the keys in this source, and their values.
    #
    # @yield every key/value in the source
    # @yieldparam [String] key in UPPER_UNDERSCORE notation
    # @yieldparam [Object] value of key
    def each_pair(&_block)
      @env.each_pair do |key, value|
        yield(key, value)
      end
    end

    private

    # Converts the dotted notation to a environment notation. If a @prefix is set, it applies the prefix.
    # @example
    #   "common.proxy.endpoints" => COMMON_PROXY_ENDPOINTS
    def dot_to_env(key)
      key = "#{@prefix}.#{key}" unless @prefix.nil?
      key.split('.').map { |e| e.upcase }.join('_')
    end
  end
end
