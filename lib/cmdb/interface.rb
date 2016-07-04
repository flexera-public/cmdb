# encoding: utf-8
require 'json'

module CMDB
  class Interface
    # Create a new instance of the CMDB interface with the specified sources.
    # @param [Array] sources list of String or URI source locations
    # @see Source.create for information on how to specify source URLs
    def initialize(*sources)
      namespaces = {}

      check_overlap(namespaces)

      @sources = []
      # Load from consul source first if one is available.
      unless Source::Consul.url.nil?
        if Source::Consul.prefixes.nil? || Source::Consul.prefixes.empty?
          @sources << Source::Consul.new('')
        else
          Source::Consul.prefixes.each do |prefix|
            @sources << Source::Consul.new(prefix)
          end
        end
      end

      # Register file sources with CMDB
      namespaces.each do |_, v|
        @sources << v.first
      end

      # Finally, register the environment as a source
      @sources << CMDB::Source::Environment.new
    end

    # Retrieve the value of a CMDB key, searching all sources in the order they were initialized.
    #
    # @return [Object,nil] the value of the key, or nil if key not found
    # @param [String] key
    # @raise [BadKey] if the key name is malformed
    def get(key)
      raise BadKey.new(key) unless key =~ VALID_KEY
      value = nil

      @sources.each do |s|
        value = s.get(key)
        break unless value.nil?
      end

      value
    end

    # Retrieve the value of a CMDB key; raise an exception if the key is not found.
    #
    # @return [Object,nil] the value of the key
    # @param [String] key
    # @raise [MissingKey] if the key is absent from the CMDB
    # @raise [BadKey] if the key name is malformed
    def get!(key)
      get(key) || raise(MissingKey.new(key))
    end

    # Set the value of a CMDB key.
    #
    # @return [Source,ni] the source that accepted the write, if any
    def set(key, value)
      @sources.reverse.each do |s|
        if s.respond_to?(:set)
          s.set(key, value)
          return s
        end
      end

      nil
    end

    # Enumerate all of the keys in the CMDB.
    #
    # @yield every key/value in the CMDB
    # @yieldparam [String] key
    # @yieldparam [Object] value
    # @return [Interface] always returns self
    def each_pair(&block)
      @sources.each do |s|
        s.each_pair(&block)
      end

      self
    end

    def search(prefix)
      prefix = Regexp.new('^' + Regexp.escape(key_to_env(prefix)))
      result = {}

      @sources.each do |s|
        s.each_pair do |k, v|
          result[k] = v if k =~ prefix
        end
      end

      result
    end

    # Transform the entire CMDB into a flat Hash that can be merged into ENV.
    # Key names are transformed into underscore-separated, uppercase strings;
    # all runs of non-alphanumeric, non-underscore characters are tranformed
    # into a single underscore.
    #
    # The transformation rules make it possible for key names to conflict,
    # e.g. "apple.orange.pear" and "apple.orange_pear" cannot exist in
    # the same flat hash. This method checks for such conflicts and raises
    # rather than returning bad data.
    #
    # @raise [NameConflict] if two or more key names transform to the same
    def to_h
      values = {}
      sources = {}

      each_pair do |key, value|
        env_key = key_to_env(key)
        value = JSON.dump(value) unless value.is_a?(String)

        if sources.key?(env_key)
          raise NameConflict.new(env_key, [sources[env_key], key])
        else
          sources[env_key] = key
          values[env_key] = value_to_env(value)
        end
      end

      values
    end

    private

    # Check for overlapping namespaces and react appropriately. This can happen when a file
    # of a given name is located in more than one of the key-search directories. We tolerate
    # this in development mode, but raise an exception otherwise.
    def check_overlap(namespaces)
      overlapping = namespaces.select { |_, sources| sources.size > 1 }
      overlapping.each do |ns, sources|
        exc = ValueConflict.new(ns, sources)

        CMDB.log.warn exc.message
        raise exc unless CMDB.development?
      end
    end

    # Make an environment variable out of a key name
    def key_to_env(key)
      env_name = key
      env_name.gsub!(/[^A-Za-z0-9_]+/, '_')
      env_name.upcase!
      env_name
    end

    # Make a CMDB value storable in the process environment (ENV hash)
    def value_to_env(value)
      case value
      when String
        value
      else
        JSON.dump(value)
      end
    end
  end
end
