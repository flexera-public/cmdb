# encoding: utf-8
require 'pp'

module CMDB::Commands
  class Shell
    def self.create(interface)
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

    # @param [CMDB::Interface] interface
    def initialize(interface)
      @cmdb = interface
    end

    # Run the shim.
    #
    # @raise [SystemExit] if something goes wrong
    def run
      @self = Self.new(cmdb)
      repl
    end

    private

    def prompt
      "cmdb:/#{@self.pwd.join('/')}> "
    end

    def repl
      require 'readline'
      while line = Readline.readline(prompt, true)
        begin
          line = line.chomp
          # First, try a Ruby command
          words = line.split(/\s+/)
          command, args = words.first.to_sym, words[1..-1]
          run_ruby(command, args) || run_getter(line) || run_setter(line) ||
            fail(CMDB::BadCommand.new('command not found', command))
        rescue => e
          handle_error(e) || raise
        end
      end
    rescue Interrupt
      return 0
    end

    def run_ruby(command, args)
      if @self.respond_to?(command)
        result = @self.__send__(command, *args)
        @self._= result
        true
      else
        false
      end
    end

    def run_getter(key)

      if value = @self.get(key)
        @self._= value
        true
      else
        false
      end
    rescue CMDB::Error
      false
    end

    def run_setter(line)
      key, value = line.chomp.strip.split(/\s*=\s*/, 2)
      return false unless key

      value = nil unless value && value.length > 0
      @self.set(key, value)
      @self._= value
      true
    rescue CMDB::Error
      false
    end

    # @return [Boolean] print message and return true if error is handled; else return false
    def handle_error(e)
      case e
      when CMDB::BadCommand
        puts "cmdb: Unrecognized command '#{e.name}'"
        true
      when ArgumentError then puts "cmdb: Too many/few arguments"
        true
      else
        false
      end
    end

    class Self
      # @return [Object] result of the last command
      attr_accessor :_

      attr_reader :pwd

      def initialize(cmdb)
        @cmdb = cmdb
        @pwd = []
      end

      def ls(prefix='')
        prefix = (pwd.join('.') + '.') + prefix unless pwd.empty?

        results = @cmdb.search(prefix)
        pp results
      end

      def help
        puts 'Commands:'
        puts '  cd slash/sep/path - append to search prefix'
        puts '  cd /path          - reset prefix'
        puts '  ls                - show keys and values'
        puts '  <key>             - print value of key'
        puts '  <key>=<value>     - set env key to value'
      end

      def get(key)
        pp @cmdb.get(key)
      end

      def set(key, value)
        @cmdb.set(key, value)
        @cmdb.get(key)
      end

      def cd(key)
        if key[0] == '/'
          parts = key[0..-1].split('/')
          dir = parts.dup
        else
          parts = key.split('/')
          dir = pwd
        end

        parts.each do |p|
          case p
          when '..'
            dir.pop
          else
            dir.push(p)
          end
        end

        @pwd = dir
      end

      def quit
        raise Interrupt
      end
      alias exit quit
    end
  end
end
