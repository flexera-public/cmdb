### 3.0.0rc1

With this major version we introduce significant compatibility-breaking changes!
Functions and options have been removed and we have rethought how sources are
specified.

#### New: Interactive shell

A `shell` subcommand allows you to navigate the CMDB as if it were a
filesystem with `ls`, `cd` and other commands.

#### New: Read/write sources

Non-file sources allow keys to be written as well as read. You can set the values
of keys from the shell, or programatically by calling the `#set` method of the
source.

#### Changed: Command-line interface

The `cmdb` command now supports a number of common options that apply to all
subcommands.

Rather than have a hodgepodge of CLI options for each type of source, all sources 
are represented by URLs where the scheme tells the gem what type of source to 
create: `env:`, `file://`, or `consul://`. You can specify as many sources as
you'd like by passing `--source` option multiple times with different URLs.

If you omit `--source` entirely, the CLI will scan the network for common
locations of supported sources. If it finds nothing, it will exit with an
error.
 
#### Changed: data file locations

The gem no longer scans fixed directories for JSON/YML files on startup; you 
must explicitly provide the locations of every file that has CMDB keys by
passing the `--source` option.

### Changed: shim command

The `--dir` option has been renamed to `--rewrite` for clarity.

The `--reload` and --reload-signal` options are no longer supported; CMDB has
lost its ability to reload the app when your files change. As a result, we
no longer depend on the `listen` gem.

The option to specify a `--root` for the CMDB interface as a whole has been 
removed.
#### Implementation changes

The dependency on Diplomat has been removed; we now speak to consul without a
middleman.

#### Design changes

All sources have a new common base class `Source`, which also serves as an
enclosing namespace for all derived classes (`Source::Consul`, 
`Source::Environment`, etc).

### 2.6.0 (2016-03-01)

Two new command line options are added to the shim
`--consul-url` = The URL of the consul agent. Example: http://consul:8500
`--consul-prefix` = The prefix to use when getting keys from consul. Example: shard403

There are two ways of using the shim.

1. Using to replace keys in legacy ruby apps:
---------------------------------------------

When using the shim to replace keys in configuration files, it is sufficient to specify
the shard identifier (shard403, shard93, etc) as the prefix. Also prefix is optional so
in dev environments if you don't have these shard identifier as prefixes, you don't have
to specify it. When replacing keys in configuration files, the requested keys are loaded
from consul on demand.

Example:
```
bundle exec cmdb shim --consul-url=http://consul:8500 --consul-prefix=shard403 \
  --dir=config -- rainbows -c config/rainbows.rb
```

2. Using to populate environment in modern apps:
------------------------------------------------

The --consul-prefix command line option can be specifed multiple times just like the
envconsul tool allows and all keys under the specified prefix are loaded in the
environment and the prefix itself is skipped.

Example:
```
bundle exec cmdb shim --consul-url=http://consul:8500 --consul-prefix=shard403/common \
  --consul-prefix=shard403/cwf_public_service --env -- rainbows -c config/rainbows.rb
```

### 2.5.0 (2015-07-16)

So many changes! View the diffs for info.

### 2.1.0

Initial release. Contains the following features:
 - API for querying a CMDB
 - Command-line shim for rewriting config files
 - Server restart feature to aid debugging
