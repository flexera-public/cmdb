# encoding: utf-8

module CMDB::Commands
  class Shell
    # Character that acts as a separator between key components. The standard
    # notation uses `.` but Shell allow allows `/` for a more filesystem-like
    # user experience.
    ALT_SEPARATOR = '/'.freeze

    # Directory navigation shortcuts ('.' and '..')
    NAVIGATION = /^#{Regexp.escape(CMDB::SEPARATOR + CMDB::SEPARATOR)}?$/.freeze

    def self.create(interface)
      require 'cmdb/shell'

      options = Trollop.options do
        banner <<-EOS
The 'shell' command enters a Unix-like shell where you can interact with
CMDB sources and inspect the value of keys.

Usage:
cmdb shell
        EOS
      end

      new(interface)
    end

    # @return [CMDB::Interface]
    attr_reader :cmdb

    # @return [CMDB::Shell::DSL]
    attr_reader :dsl

    # @return [Array] the "present working directory" (i.e. key prefix) for shell commands
    attr_accessor :pwd

    # @return [Object] esult of the most recent command
    attr_accessor :_

    # @param [CMDB::Interface] interface
    def initialize(interface)
      @cmdb = interface
      @pwd = []
      text = CMDB::Shell::Text.new(!$stdout.tty? || ENV['TERM'].nil?)
      @out = CMDB::Shell::Printer.new($stdout, $stderr, text)
      @in  = CMDB::Shell::Prompter.new(text)
    end

    # Run the shim.
    #
    # @raise [SystemExit] if something goes wrong
    def run
      @dsl = CMDB::Shell::DSL.new(self, @out)
      repl
    end

    # Given a key name/prefix relative to `pwd`, return the absolute
    # name/prefix. If `pwd` is empty, just return `subpath`. The subpath
    # can use either dotted or slash notation, and directory navigation
    # symbols (`.` and `..`) are applied as expected if the subpath uses
    # slash notation.
    #
    # @return [String] absolute key in dotted notation
    def expand_path(subpath)
      if subpath[0] == ALT_SEPARATOR
        result = []
      else
        result = pwd.dup
      end

      if subpath.include?(ALT_SEPARATOR) || subpath =~ NAVIGATION
        # filesystem-like subpath
        # apply Unix-style directory navigation shortcuts
        pieces = subpath.split(ALT_SEPARATOR).select { |p| !p.nil? && !p.empty? }
        pieces.each do |piece|
          case piece
          when '..' then result.pop
          when '.' then nil
          else result.push(piece)
          end
        end

        result.join(CMDB::SEPARATOR)
      else
        pieces = subpath.split(CMDB::SEPARATOR).select { |p| !p.nil? && !p.empty? }
        # standard dotted notation
        result += pieces
      end

      result.join(CMDB::SEPARATOR)
    end

    private

    def repl
      while line = @in.read(self)
        begin
          line = line.chomp
          next if line.nil? || line.empty?
          words = line.split(/\s+/)
          command, args = words.first.to_sym, words[1..-1]

          run_ruby(command, args) || run_getter(line) || run_setter(line) ||
            fail(CMDB::BadCommand.new(command))
          handle_output(self._)
        rescue SystemCallError => e
          handle_error(e) || raise
        rescue => e
          handle_error(e) || raise
        end
      end
    rescue Interrupt
      return 0
    end

    # @return [Boolean] true if line was handled as a normal command
    def run_ruby(command, args)
      self._ = @dsl.__send__(command, *args)
      true
    rescue CMDB::BadCommand
      false
    rescue ArgumentError => e
      raise CMDB::BadCommand.new(e.message, command)
    end

    # @return [Boolean] true if line was handled as a getter
    def run_getter(key)
      if value = @dsl.get(key)
        self._ = value
        true
      else
        false
      end
    rescue CMDB::BadKey
      false
    end

    # @return [Boolean] true if line was handled as a setter
    def run_setter(line)
      key, value = line.strip.split(/\s*=\s*/, 2)
      return false unless key && value

      value = nil unless value && value.length > 0
      self._ = @dsl.set(key, value)
      true
    end

    def handle_output(obj)
      case obj
      when Hash
        @out.keys_values(obj, prefix:pwd.join('.'))
      else
        @out.value(obj)
      end
    end

    # @return [Boolean] print message and return true if error is handled; else return false
    def handle_error(e)
      case e
      when CMDB::BadCommand
        @out.error "#{e.command}: #{e.message}"
        true
      when CMDB::Error
        @out.error e.message
        true
      when SystemCallError
        @out.error "#{e.class.name}: #{e.message}"
      else
        false
      end
    end
  end
end
