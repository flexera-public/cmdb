# encoding: utf-8
require 'set'
require 'singleton'

module CMDB
  # Values of RACK_ENV/RAILS_ENV that are considered to be "development," which relaxes
  # certain runtime sanity checks.
  DEVELOPMENT_ENVIRONMENTS = [nil, 'development', 'test'].freeze

  # Regexp that matches valid key names. Key names consist of one or more dot-separated words;
  # each word must begin with a lowercase alpha character and may contain alphanumerics or
  # underscores.
  VALID_KEY = /^[a-z][a-z0-9_]*(?:\.[a-z][a-z0-9_]*)*$/

  class Error < StandardError; end

  # Client asserted the existence of a key that does not exist in the CMDB.
  class MissingKey < Error
    # @return [String] the name of the offending key
    attr_reader :key

    # @param [String] name
    def initialize(key)
      @key = key
      super("Key '#{key}' not found in CMDB")
    end
  end

  # Client asked for an invalid or malformed key name.
  class BadKey < Error
    # @return [String] the name of the offending key
    attr_reader :key

    # @param [String] name
    def initialize(key)
      @key = key
      super("Malformed key '#{key}'")
    end
  end

  # A value of an unsupported type was encountered in the CMDB.
  class BadValue < Error
    # @return [URI] filesystem or network location of the bad value
    attr_reader :url

    # @return [String] the name of the key that contained the bad value
    attr_reader :key

    # @param [URI] url filesystem or network location of the bad value
    # @param [String] key CMDB key name under which the bad value was found
    # @param [Object] value the bad value itself
    def initialize(url, key, value)
      @url = url
      @key = key
      super("Values of type #{value.class.name} are unsupported")
    end
  end

  # Malformed data was encountered in the CMDB or in an app's filesystem.
  class BadData < Error
    # @return [URI] filesystem or network location of the bad data
    attr_reader :url

    # @param [URI] url filesystem or network location of the bad value
    # @param [String] context brief description of where data was found e.g. 'CMDB data file' or 'input config file'
    def initialize(url, context = nil)
      @url = url
      super("Malformed data encountered #{(' in ' + context) if context}")
    end
  end

  # Two or more sources contain keys for the same namespace; this is only allowed in development
  # environments.
  class ValueConflict < Error
    attr_reader :sources

    def initialize(ns, sources)
      @sources = sources
      super("Keys for namespace #{ns} are defined in #{sources.size} overlapping sources")
    end
  end

  # Deprecated name for ValueConflict
  Conflict = ValueConflict

  # Two or more keys in different namespaces have an identical name. This isn't an error
  # when CMDB is used to refer to keys by their full, qualified name, but it can become
  # an issue when loading keys into the environment for 12-factor apps to process.
  class NameConflict < Error
    attr_reader :env
    attr_reader :keys

    def initialize(env, keys)
      @env = env
      @keys = keys
      super("#{env} corresponds to #{keys.size} different keys")
    end
  end

  # The CMDB is being exported to ENV, but one of its keys would overwrite a value that
  # is already present in ENV. This should never happen, because the CMDB is designed to
  # _augment_ the environment by providing a place to store boring (static, non-secret)
  # inputs, and a given input should be set either in the CMDB or the environment, never
  # both.
  #
  class EnvironmentConflict < Error
    attr_reader :key

    def initialize(key)
      @key = key
      super("#{key} is already present in the environment; cannot override with CMDB values")
    end
  end

  module_function

  def log
    unless @log
      @log = Logger.new(STDOUT)
      @log.level = Logger::WARN
    end

    @log
  end

  def log=(log)
    @log = log
  end

  # Determine whether CMDB is running in a development environment.
  # @return [Boolean]
  def development?
    DEVELOPMENT_ENVIRONMENTS.include?(ENV['RACK_ENV'] || ENV['RAILS_ENV'])
  end
end

require 'cmdb/consul_source'
require 'cmdb/file_source'
require 'cmdb/interface'
require 'cmdb/rewriter'
require 'cmdb/commands'
