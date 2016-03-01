# encoding: utf-8
require 'yaml'
require 'json'

module CMDB
  # Tool that visits every file in a hierarchy and rewrites its references to CMDB inputs.
  #
  # References look like <<name.of.key>> and may be replaced with a scalar value
  # or an array depending on the type of the input value.
  class Rewriter
    attr_reader :missing_keys

    # Create a new shim to rewrite config files in a chosen dir and all subdirs.
    # config_dir is transformed into an absolute path (if it isn't already)
    # before any rewrite operations occur.
    #
    # @param [String,Pathname] config_dir
    def initialize(config_dir)
      @dir = File.expand_path(config_dir)
      @rewriters = []
    end

    # Substitute CMDB input values into config files whenever a replacement token is encountered.
    #
    # @param [CMDB::Interface] cmdb
    # @return [Integer] the number of variables replaced
    def rewrite(cmdb)
      raise Errno::ENOENT.new(@dir) unless File.directory?(@dir)

      visit(@dir)
      total = 0
      @rewriters.each { |rw| total += rw.rewrite(cmdb) }

      @missing_keys = @rewriters.map(&:missing_keys).flatten.uniq.sort

      total
    end

    def save
      @rewriters.each(&:save)
      true
    end

    private

    # Recursively scan location for files to rewrite.
    def visit(location)
      if File.file?(location)
        scan(location)
      elsif File.directory?(location)
        entries = Dir.glob("#{location}/*")
        subdirs = entries.select { |e| File.directory?(e) }
        files   = entries.select { |e| File.file?(e) }

        subdirs.each do |entry|
          visit(entry)
        end

        files.each do |entry|
          visit(entry)
        end
      end
    end

    # Load a data file and attach a rewriter to it.
    def scan(file)
      case File.extname(file)
      when '.yml', '.yaml'
        @rewriters << FileRewriter.new(file, YAML)
      when '.js', '.json'
        @rewriters << FileRewriter.new(file, JSON)
      end
    end
  end

  # Tool that rewrites the contents of a single YAML, JSON or similar data file.
  # The rewriting is done in-memory and isn't saved back to disk until someone
  # calls #save, allowing the caller to check #missing_keys before making a
  # decision whether to proceed.
  class FileRewriter
    # Regexp that matches a well-formed replacement token in YML or JSON
    REPLACEMENT_TOKEN = /^<<(.*)>>$/

    attr_reader :missing_keys

    # Load YAML, JSON or similar into memory as a Ruby object graph.
    def initialize(file, encoder)
      @file = file
      @encoder = encoder
      @data = @encoder.load(File.read(file))
    end

    # Peform CMDB input replacement on in-memory objects. Validate that the result can be saved.
    #
    # @return [Integer] number of variables replaced
    def rewrite(cmdb)
      @total = 0
      @missing_keys = []
      @data = visit(cmdb, @data)

      # Very important; DO NOT REMOVE. This is how we validate that #save will work.
      @encoder.dump(@data)
      raise Errno::EACCES.new(@file) unless File.writable?(@file)

      @total
    end

    def save
      File.open(@file, 'w') { |f| f.write @encoder.dump(@data) }
    end

    private

    # Recurse through an object graph, finding replacement tokens and substituting the
    # corresponding CMDB values.
    def visit(cmdb, node)
      if node.is_a?(Hash)
        result = {}
        node.each_pair do |k, v|
          result[k] = visit(cmdb, v)
        end
      elsif node.is_a?(Array)
        result = []
        node.each do |v|
          result << visit(cmdb, v)
        end
      elsif node.is_a?(String) && (m = REPLACEMENT_TOKEN.match(node))
        value = cmdb.get(m[1])
        if value.nil?
          @missing_keys << m[1]
        else
          result = value
          @total += 1
        end
      else
        result = node
      end

      result
    end
  end
end
