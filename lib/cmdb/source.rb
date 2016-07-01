module CMDB
  class Source
    # @return [nil,String] common dot-notation prefix of this source's keys, if any
    attr_reader :prefix

    # @return [URI] a file or network URL describing where this source's data comes from
    attr_reader :url

    # Construct a source given a URI that identifies both the type of
    # source (consul, file or environment) and its location if applicable.
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
    # @example consul source with no prefix
    #   CMDB::Source.create('consul://localhost')
    #
    # @example consul source with nonstandard location and port
    #   CMDB::Source.create('consul://my-kv:18500')
    #
    # @example consul source whose keys are drawn from a subtree of the k/v
    #   CMDB::Source.create('consul://localhost/interesting-keys')
    def self.create(uri)
      uri = URI.parse(uri) if uri.is_a?(String)

      case uri.scheme
      when 'consul'
        curi = uri.dup
        curi.scheme = 'http'
        curi.port ||= 8500
        curi.path = ''
        ConsulSource.new(URI.parse(curi.to_s), prefix)
      when 'file'
        FileSource.new(uri.path)
      when 'env'
        EnvironmentSource.new
      else
        raise ArgumentError, "Unrecognized URL scheme '#{uri.scheme}'"
      end
    end
  end
end
