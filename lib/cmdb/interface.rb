# encoding: utf-8
require 'json'

module CMDB
  class Interface
    # Create a new instance of the CMDB interface with the specified sources.
    # @param [Array] sources list of String or URI source locations
    # @see Source.create for information on how to specify source URLs
    def initialize(*sources)
      # ensure no two sources share a prefix
      prefixes = {}
      sources.each do |s|
        next if s.prefix.nil?
        prefixes[s.prefix] ||= []
        prefixes[s.prefix] << s
      end
      check_overlap(prefixes)

      @sources = sources.dup
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
    # @raise [BadKey] if the key name is malformed
    def set(key, value)
      raise BadKey.new(key) unless key =~ VALID_KEY

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
      prefix = Regexp.new('^' + Regexp.escape(prefix))
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
    def to_env
      values = {}
      originals = {}

      @sources.each do |s|
        s.each_pair do |k, v|
          env = key_to_env(k, s)
          if (orig = originals[env])
            raise NameConflict.new(env, [orig, k])
          else
            values[env] = value_to_env(v)
            originals[env] = k
          end
        end
      end

      values
    end

    private

    # Check that no two sources share a prefix. Raise an exception if any
    # overlap is detected.
    def check_overlap(prefix_sources)
      overlapping = prefix_sources.select { |_, sources| sources.size > 1 }
      overlapping.each do |p, sources|
        exc = ValueConflict.new(p, sources)

        CMDB.log.error exc.message
        raise exc
      end
    end

    # Make an environment variable out of a key name
    def key_to_env(key, source)
      if source.prefix
        env_name = key[source.prefix.size+1..-1]
      else
        env_name = key.dup
      end
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
