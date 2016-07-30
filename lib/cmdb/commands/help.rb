# encoding: utf-8

module CMDB::Commands
  class Help
    def self.create(interface)
      new(interface, ARGV.first)
    end

    def initialize(interface, command)
      @cmdb = interface
      @command = command
    end

    def run
      if @command.nil? || @command.empty?
        # Same as "--help"
        raise Trollop::HelpNeeded
      end

      # Find the command the user was talking about and print some help
      konst = CMDB::Commands.constants.detect { |konst| konst.to_s.downcase == @command }
      if konst
        klass = CMDB::Commands.const_get(konst)
        ARGV.clear ; ARGV.push('--help')
        klass.create(@cmdb)
      else
        CMDB.log.fatal "CMDB: Unknown command '#{@command}'; try 'cmdb --help' for a list of commands"
        exit 1
      end
    end
  end
end
