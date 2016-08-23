module CMDB
  class Source
    # Determine the prefix of all keys provided by this source. No two sources can share
    # a prefix (other than nil) and no source's prefix can be a prefix of any other
    # source's prefix.
    #
    # Some sources have no common prefix, in which case this reader returns nil.
    #
    # @return [nil,String] common and unique dot-notation prefix of this source's keys, if any
    attr_reader :prefix

    # @return [URI] a URL describing where this source's data comes from
    attr_reader :url

    # Construct a source given a URI that identifies both the type of
    # source (consul, file or environment) and its location if applicable.
    # Choose a suitable prefix for the source based on the URI contents.
    #
    # If you pass a fragment as part of the URI, then the fragment becomes the
    # prefix. Otherwise, the final path component becomes the prefix, unless
    # it is empty in which case the first hostname component becomes the prefix.
    #
    # @param [String,URI] location of source
    #
    # @raise ArgumentError if URL scheme is unrecognized
    #
    # @example environment source
    #   CMDB::Source.create('env')
    #
    # @example JSON source
    #   CMDB::Source.create('file://awesome.json')
    #
    # @example YAML source
    #   CMDB::Source.create('file://awesome.yml')
    #
    # @example consul source at the root of the k/v tree with prefix "otherhost" (probably not desirable!)
    #   CMDB::Source.create('consul://otherhost.example.com')
    #
    # @example consul source at the root of the k/v tree with prefix "myapp"
    #   CMDB::Source.create('consul://otherhost.example.com#myapp')
    #
    # @example consul source whose keys are drawn from a subtree of the k/v with prefix "interesting."
    #   CMDB::Source.create('consul://localhost/interesting')
    #
    # @example consul source with nonstandard location and port and prefix "my-kv"
    #   CMDB::Source.create('consul://my-kv:18500')
    def self.create(uri)
      uri = URI.parse(uri) if uri.is_a?(String)

      if !uri.path.nil? && !uri.path.empty?
        prefix = ::File.basename(uri.path, '.*')
      else
        prefix = nil
      end

      case uri.scheme
      when 'consul'
        curi = uri.dup
        curi.scheme = 'http'
        curi.port ||= 8500
        curi.path = ''
        Source::Consul.new(URI.parse(curi.to_s), prefix)
      when 'file'
        Source::File.new(uri.path, prefix)
      when 'memory'
        Source::Memory.new({},nil)
      else
        raise ArgumentError, "Unrecognized URL scheme '#{uri.scheme}'"
      end
    end

    # Test for the presence of some default sources and return any that exist.
    #
    # @return [Array] a set of initialized CMDB sources
    def self.detect
      sources = []

      consul = create('consul://localhost')
      sources << consul if consul.ping

      sources
    end

    private

    # Check whether a key's prefix is suitable for this source.
    def prefixed?(key)
      prefix.nil? || (key.index(prefix) == 0 && key[prefix.size] == '.')
    end
  end
end

require 'cmdb/source/memory'
require 'cmdb/source/file'
require 'cmdb/source/network'
require 'cmdb/source/consul'
