module CMDB::Shell
  # Host for CMDB command methods. Every public method of this class is
  # a CMDB command and its parameters represent the arguments to the
  # command. If a command is successful, it always updates the `_` attribute
  # with the output (return value) of the command.
  class DSL < BasicObject
    def initialize(shell, out)
      @shell = shell
      @cmdb = @shell.cmdb
      @out = out
    end

    def ls(path='')
      prefix = @shell.expand_path(path)
      @cmdb.search prefix
    end

    def help
      @out.info 'Commands:'
      @out.info '  cd slash/sep/path - append to search prefix'
      @out.info '  cd /path          - reset prefix'
      @out.info '  get <key>         - print value of key'
      @out.info '  ls                - show keys and values'
      @out.info '  set <key> <value> - print value of key'
      @out.info '  quit              - exit the shell'
      @out.info 'Notation:'
      @out.info '  a.b.c             - (sub)key relative to search prefix'
      @out.info '  ../b/c            - the b.c subkey relative to parent of search prefix'
      @out.info 'Shortcuts:'
      @out.info '  <key>             - for get'
      @out.info '  <key>=<value>     - for set'
      @out.info '  cat,rm,unset,...  - as expected'
    end

    def get(key)
      key = @shell.expand_path(key)

      @cmdb.get(key)
    end
    alias cat get

    def set(key, value)
      key = @shell.expand_path key

      if @cmdb.set(key, value)
        @cmdb.get(key)
      else
        ::Kernel.raise ::CMDB::BadCommand.new("No source is capable of accepting writes", "set")
      end
    end

    def unset(key)
      @cmdb.set(key, nil)
    end
    alias rm unset

    def cd(path)
      pwd = @shell.expand_path(path)
      @shell.pwd = pwd.split(::CMDB::SEPARATOR)
      pwd.to_sym
    end
    alias chdir cd

    def pry

    end

    def quit
      ::Kernel.raise ::Interrupt
    end
    alias exit quit
  end
end
