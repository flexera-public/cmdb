require 'uri'

module CMDB
  # Data source that is backed by a YAML file that lives in the filesystem. The name of the YAML
  # file becomes the top-level key under which all values in the YAML are exposed, preserving
  # their exact structure as parsed by YAML.
  #
  # @example Use my.yml as a CMDB source
  #    source = FileSource.new('/tmp/my.yml') # contains a top-level stanza named "database"
  #    source['my']['database']['host'] # => 'db1-1.example.com'
  class FileSource
    # @return [URI] a file:// URL describing where this source's data comes from
    attr_reader :prefix, :url

    @@base_directories = ['/var/lib/cmdb', File.expand_path('~/.cmdb')]

    # List of directories that will be searched (in order) for YML files at load time.
    # @return [Array] collection of String
    def self.base_directories
      @@base_directories
    end

    # @param [Array] bd collection of String absolute paths to search for YML files
    def self.base_directories=(bd)
      @@base_directories = bd
    end

    # Construct a new FileSource from an input YML file.
    # @param [String,Pathname] filename path to a YAML file
    # @raise [BadData] if the file's content is malformed
    def initialize(filename, root=nil)
      filename = File.expand_path(filename)
      @url = URI.parse("file://#{filename}")
      @prefix = File.basename(filename, ".*")
      @extension = File.extname(filename)
      @data = {}

      raw_bytes = File.read(filename)
      raw_data  = nil

      begin
        case @extension
        when /jso?n?$/i
          raw_data = JSON.load(raw_bytes)
        when /ya?ml$/i
          raw_data = YAML.load(raw_bytes)
        else
          raise BadData.new(self.url, 'file with unknown extension; expected js(on) or y(a)ml')
        end
      rescue Exception
        raise BadData.new(self.url, 'CMDB data file')
      end

      raw_data = raw_data[root] if !root.nil? && raw_data.key?(root)
      flatten(raw_data, @prefix, @data)
    end

    # Get the value of key.
    #
    # @return [nil,String,Numeric,TrueClass,FalseClass,Array] the key's value, or nil if not found
    def get(key)
      @data[key]
    end

    # Enumerate the keys in this source, and their values.
    #
    # @yield every key/value in the source
    # @yieldparam [String] key
    # @yieldparam [Object] value
    def each_pair(&block)
      # Strip the prefix in the key and call the block
      @data.each_pair { |k, v| block.call(k.split("#{@prefix}.").last, v) }
    end

    private

    def flatten(data, prefix, output)
      data.each_pair do |key, value|
        key = "#{prefix}.#{key}"
        case value
        when Hash
          flatten(value, key, output)
        when Array
          if value.all? { |e| e.is_a?(String) } ||
               value.all? { |e| e.is_a?(Numeric) } ||
               value.all? { |e| e == true } ||
               value.all? { |e| e == false }
            output[key] = value
          else
            # mismatched arrays: not allowed
            raise BadValue.new(self.url, key, value)
          end
        when String, Numeric, TrueClass, FalseClass
          output[key] = value
        else
          # nil and anything else: not allowed
          raise BadValue.new(self.url, key, value)
        end
      end
    end
  end
end
