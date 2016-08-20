# encoding: utf-8

module CMDB::Commands
  class Shim
    def self.create(interface)
      options = Trollop.options do
        banner <<-EOS
The 'shim' command adapts your applications for use with CMDB without coupling them to
the CMDB RubyGem (or forcing you to write your applications in Ruby). It works by
manipulating the environment or filesystem to make CMDB inputs visible, then invoking
your app.

To use the shim with apps that read configuration from the filesystem, use the --rewrite
option to tell the shim where to rewrite configuration files. It will look for tokens
in JSON or YML that look like <<cmdb.key.name>> and replace them with the value of
the specified key.

To use the shim with 12-factor apps, use the --env option to tell the shim to load
every CMDB key into the environment. When using --env, the prefix of each key is
omitted from the environment variable name, e.g. "common.database.host" is
represented as DATABASE_HOST.

Usage:
cmdb shim [options] -- <command_to_exec> [options_for_command]

Where [options] are selected from:
        EOS
        opt :rewrite,
            'Directory to scan for key-replacement tokens in data files',
            type: :string
        opt :pretend,
            'Check for errors, but do not actually launch the app or rewrite files',
            default: false
        opt :env,
            "Add CMDB keys to the app server's process environment",
            default: false
        opt :user,
            'Switch to named user before executing app',
            type: :string
      end
      options.delete(:help)

      options.delete_if { |k, v| k.to_s =~ /_given$/i }
      new(interface, ARGV, **options)
    end

    # Irrevocably change the current user for this Unix process by calling the
    # setresuid system call. This sets both the uid and gid (to the user's primary
    # group).
    #
    # @param [String] login name of user to switch to
    # @return [true]
    # @raise [ArgumentError] if the named user does not exist
    def self.drop_privileges(login)
      pwent = Etc.getpwnam(login)
      Process::Sys.setresgid(pwent.gid, pwent.gid, pwent.gid)
      Process::Sys.setresuid(pwent.uid, pwent.uid, pwent.uid)
      true
    end

    # @return [CMDB::Interface]
    attr_reader :cmdb

    # Create a Shim.
    # @param [Array] command collection of string to pass to Kernel#exec; 0th element is the command name
    def initialize(interface, command, rewrite:, pretend:, env:, user:)
      @cmdb            = interface
      @command         = command
      @dir             = rewrite
      @pretend         = pretend
      @env             = env
      @user            = user
    end

    # Run the shim.
    #
    # @raise [SystemExit] if something goes wrong
    def run
      rewrote   = rewrite_files
      populated = populate_environment

      if !rewrote && !populated && !@pretend && @command.empty?
        CMDB.log.warn 'CMDB: nothing to do; please specify --dir, --env, or a command to run'
        exit 7
      end

      launch_app
    rescue CMDB::BadKey => e
      CMDB.log.fatal "CMDB: Bad Key: malformed CMDB key '#{e.key}'"
      exit 1
    rescue CMDB::BadValue => e
      CMDB.log.fatal "CMDB: Bad Value: illegal value for CMDB key '#{e.key}' in source #{e.url}"
      exit 2
    rescue CMDB::BadData => e
      CMDB.log.fatal "CMDB: Bad Data: malformed CMDB data in source #{e.url}"
      exit 3
    rescue CMDB::ValueConflict => e
      CMDB.log.fatal "CMDB: Value Conflict: #{e.message}"
      e.sources.each do |s|
        CMDB.log.fatal " - #{s.url}"
      end
      exit 4
    rescue CMDB::NameConflict => e
      CMDB.log.fatal "CMDB: Name Conflict: #{e.message}"
      e.keys.each do |k|
        CMDB.log.fatal " - #{k}"
      end
      exit 4
    rescue CMDB::EnvironmentConflict => e
      CMDB.log.fatal "CMDB: Environment Conflict: #{e.message}"
      exit 5
    rescue Errno::ENOENT => e
      CMDB.log.fatal "CMDB: missing file or directory #{e.message}"
      exit 6
    end

    private

    # @return [Boolean]
    def rewrite_files
      return false unless @dir

      CMDB.log.info 'Starting rewrite of configuration...'

      rewriter = CMDB::Rewriter.new(@dir)

      total = rewriter.rewrite(@cmdb)

      if rewriter.missing_keys.any?
        missing = rewriter.missing_keys.map { |k| "  #{k}" }.join("\n")
        CMDB.log.error "Cannot rewrite configuration; #{rewriter.missing_keys.size} missing keys:\n#{missing}"

        exit(-rewriter.missing_keys.size)
      end

      report_rewrite(total)

      if @pretend
        false
      else
        rewriter.save
      end
    end

    # @return [Boolean]
    def populate_environment
      return false unless @env

      env = @cmdb.to_h

      env.keys.each do |k|
        raise CMDB::EnvironmentConflict.new(k) if ENV.key?(k)
      end

      if @pretend
        false
      else
        env.each_pair do |k, v|
          ENV[k] = v
        end
        true
      end
    end

    def launch_app
      if @command.any?
        CMDB.log.info "App will run as user #{@user}" if @user
        self.class.drop_privileges(@user) if @user
        exec(*@command)
      end
    end

    def report_rewrite(total)
      CMDB.log.info "Replaced #{total} variables in #{@dir}"
    end

    def interesting?(fn)
      !File.basename(fn).start_with?('.')
    end
  end
end
