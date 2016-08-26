module CMDB::Shell
  class Prompter
    def initialize(text)
      require 'readline'
      @c = text
    end

    # Prompt the user for input and read a line. Offer autocompletion services
    # using Readline and CMDB/DSL searches.
    def read(shell)
      Readline.completion_proc = proc do |word|
        commands = shell.dsl.class.instance_methods.select do |m|
          m.to_s.index(word) == 0 && m !~ /[^a-z]/
        end.map(&:to_s)
        next commands if commands.any?

        hits  = shell.cmdb.search(shell.expand_path(word)).keys
        hits.sort! { |x, y| x.size <=> y.size }
        pwd = shell.pwd.join('.')
        hits[0...CMDB::Shell::MANY].map { |k| k.sub(pwd, '') }
      end

      Readline.readline(prompt(shell.cmdb, shell.pwd), true)
    end

    private

    # Return a suitable prompt for later printing.
    #
    # @return [String] human-readable CMDB prompt
    def prompt(cmdb, pwd)
      max=@c.width/2
      pwd = '/' + pwd.join('/')
      pwd = '...' + pwd[-max..-1] if pwd.size >= max
      'cmdb:' +
        @c.green(pwd) +
        @c.default('> ')
    end
  end
end