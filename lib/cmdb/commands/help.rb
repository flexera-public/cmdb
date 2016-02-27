require 'logger'
require 'listen'

module CMDB::Commands
  class Help
    def self.create
      options = Trollop.options do
        banner <<-EOS
The 'shim' command adapts your applications for use with CMDB without coupling them to
the CMDB RubyGem (or forcing you to write your applications in Ruby). It works by
manipulating the environment or filesystem to make CMDB inputs visible, then invoking
your app.

To use the shim with apps that read configuration from the filesystem, use the --dir
option to tell the shim where to rewrite configuration files. It will look for tokens
in JSON or YML that look like <<cmdb.key.name>> and replace them with the value of
the specified key.

To use the shim with 12-factor apps, use the --env option to tell the shim to load
every CMDB key into the environment. When using --env, the prefix of each key is
omitted from the environment variable name, e.g. "common.database.host" is
represented as DATABASE_HOST.

To support "development mode" and reload your app whenever its files change on disk,
use the --reload option and specify the name of a CMDB key that will enable this
behavior.

Usage:
cmdb shim [options] -- <command_to_exec> [options_for_command]

Where [options] are selected from:
        EOS
        opt :dir,
            "Directory to scan for key-replacement tokens in data files",
            :type => :string
        opt :consul_url,
            "The URL for talking to consul",
            :type => :string
        opt :consul_prefix,
            "The prefix to use when getting keys from consul, can be specified more than once",
            :type => :string,
            :multi => true
        opt :keys,
            "Override search path(s) for CMDB key files",
            :type => :strings
        opt :pretend,
            "Check for errors, but do not actually launch the app or rewrite files",
            :default => false
        opt :quiet,
            "Don't print any output",
            :default => false
        opt :reload,
            "CMDB key that enables reload-on-edit",
            :type => :string
        opt :reload_signal,
            "Signal to send to app server when code is edited",
            :type => :string,
            :default => "HUP"
        opt :env,
            "Add CMDB keys to the app server's process environment",
            :default => false
        opt :user,
            "Switch to named user before executing app",
            :type => :string
        opt :root,
            "Promote named subkey to the root when it is present in a namespace",
            :type => :string
      end

      self.new(ARGV, options)
    end


  end
end
