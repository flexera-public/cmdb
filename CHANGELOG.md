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

#### Removed: Environment sources

We no longer treat the process environment as a _source_ for CMDB data, but
rather a destination; the use cases for treating it as a source were spurious
and mostly concerned with testing of this gem.

The `--env` option to the `cmdb shim` command is now the default behavior and
there is no way _not_ to populate the environment. We retain the safeguards
that cause CMDB to raise an error if two sources would populate the environment
with the same key name; overlap/inheritance is still disallowed.

#### Removed: Dichotomy between key enumeration and single-get

In v2, calls to `#get` were required to include a source's prefix in the key
name (e.g. `common.sandwich.size` whereas the key names returned from 
`#each_pair` lacked a prefix (e.g. `sandwich.size`). This was confusing and
served no real purpose, so all methods have been normalized to always include
the prefix in the key name.

Naturally, sources with a nil prefix do not enforce this requirement!

It is safe to call `#get` on a source whose prefix does not match; the source
will simply return nil. However, calling `#set` with an invalid key prefix
will cause settable sources to raise `CMDB::BadKey`.

#### Changed: Command-line interface

The `cmdb` command now supports a number of common options that apply to all
subcommands.

Rather than have a hodgepodge of CLI options for each type of source, all sources 
are represented by URLs where the scheme tells the gem what type of source to 
create: `file://`, or `consul://`. You can specify as many sources as
you'd like by passing `--source` option multiple times with different URLs.

If you omit `--source` entirely, the CLI will scan the network for common
locations of supported sources. If it finds nothing, it will exit with an
error.
 
#### Changed: data file locations

The gem no longer scans fixed directories for JSON/YML files on startup; you 
must explicitly provide the locations of every file that has CMDB keys by
passing `--source=file:///foo/bar.yml` to the CLI.

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
`Source::File`, etc).
