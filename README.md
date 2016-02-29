# CMDB

[![TravisCI][travis_ci_img]](https://travis-ci.org/rightscale/cmdb)
[travis_ci_img]: https://travis-ci.org/rightscale/cmdb.svg?branch=master

*NOTE:* this gem is under heavy development and it is likely that v3 will contain several interface-breaking
changes and simplifications. We encourage you to play with our toys and give us feedback on how you would
like to see the project evolve, but if you use this gem for production-grade software, please make sure to
pin to version `~> 2.6` in your Gemfile to avoid breakage!

CMDB is a Ruby interface for consuming data from one or more configuration management databases
(CMDBs) and making that information available to Web applications.

It is intended to support multiple CM technologies, including:
  - JSON/YAML files on a local disk
  - consul
  - (someday) etcd
  - (someday) ZooKeeper

Maintained by
 - [RightScale Inc.](https://www.rightscale.com)

## Why should I use this gem?

CMDB supports two primary use cases:

  1. Decouple your modern (12-factor) application from the CM mechanism that is used to deploy it,
     transforming CMDB keys and values into the enviroment variables that your app expects.
  2. Help you deploy your "legacy" application that expects its configuration to be written to
     disk files, rewriting those files with data taken from the CMDB.

The gem has two primary interfaces:
- The `cmdb shim` command populates the environment with values and/or rewrites hardcoded
  config files, then spawns your application. It can also be told to watch the filesystem for changes and
  send a signal e.g. `SIGHUP` to your application, bringing reload-on-edit functionality to any app.
- The `CMDB::Interface` object provides a programmatic API for querying CMDBs. Its `#to_h`
  method transforms the whole configuration into an environment-friendly hash if you prefer to seed the
  environment yourself, without using the shim.

# Getting Started

## Create CMDB Data Files

The shim looks in two locations to find data files. In order of precedence:

  1. `/var/lib/cmdb` -- typically at deployment time
  2. `~/.cmdb` -- useful for developers when testing the app

The base name (minus extension) of each file is important; it determines the top-level name of
the keys in that file and it *must be unique* across all of the directories. For instance,
`my_app.json` defines CMDB keys in the `my_app.*` hierarchy.

Create a data file in one of these directories; for example, you might create `my_app.yml` with
the following contents:

    db:
      hostname: db1.local
    widgets:
      flavors:
        - vanilla
        - chocolate

## Invoke the CMDB Shim

For non-Ruby applications, or for situations where CMDB values are required
outside of the context of interpreted code, use `cmdb shim` to run
your application. The shim can do several things for you:

1. Make CMDB values available to your app (in `ENV`, or by rewriting files)
2. Change the user before invoking your app (e.g. drop privileges to `www-data`)
3. Watch for filesystem changes and reload your app on demand

### Populate the environment for a dotenv-compatible application

If you have an app that uses 12-factor (dotenv) style configuration, the shim
can populate the environment with CMDB values:

    bundle exec cmdb shim --env

    # Now your app can refer to ENV['DB_HOSTNAME'] or ENV['WIDGETS_FLAVORS]
    # Note missing "my_app" prefix that would be present if you asked for these using their CMDB key names

Note that the data type of CMDB inputs is preserved: lists remain lists, numbers remain numbers,
and so forth. This works irrespective of the format of your configuration files, and also holds true
for CMDB values that are serialized to the environment (as a JSON document, in the case of lists).

### Rewriting configuration files with CMDB values

If the `--dir` option is provided, the shim recursively scans your working
directory (`Dir.pwd`) for data files that contain replacement tokens; when a token is
found, it substitutes the corresponding CMDB key's value.

Replacement tokens look like this: `<<name.of.my.key>>` and can appear anywhere in a file as a YAML
or JSON _value_ (but never a key).

Replacement tokens should appear inside string literals in your configuration files so they don't
invalidate syntax or render the files unparsable by other tools.

The shim performs replacement in-memory and saves all of the edits at once, making the rewrite
operation nearly atomic. If any keys are missing, then no files are changed on disk and the shim
exits with a helpful error message.

*NOTE:* the shim does not perform rewriting in development mode; the expectation is that your app's
configuration files will already provide reasonable dev-mode defaults and that rewriting them
is not necessary.

Given `my_app.yml` and an application with two configuration files:

    # config/database.yml
    production:
      host: <<my_app.db.hostname>
      database: my_app_production

    # config/widgets.json
    {'widgetFlavors': '<<my_app.widgets.flavors>>'}

I can run the following command in my application's root directory:

    bundle exec cmdb shim --dir=config rackup

This will rewrite the files under config, replacing my configuration files as
follows:

    # config/database.yml
    production:
      host: db1.local
      database: my_app_production

    # config/widgets.json
    {'widgetFlavors':['vanilla', 'chocolate']}

### Drop Privileges

If your app doesn't know how to safely switch to a non-privileged user, the shim
can do this for you. Just add the `--user` flag when you invoke it:

    bundle exec cmdb shim --user=www-data whoami

### Reload the App When Code Changes

You can pass the `--reload=key.name` option to `cmdb shim` in order to enable filesystem
watching. The shim will signal your application server whenever files are created,
updated or deleted, generally causing a graceful restart of the server process.

Needless to say, your app server must support graceful restart upon receipt of
a certain signal! The CMDB gem uses SIGHUP by default, but you can override this
with --reload-signal=SIGWHATEVER.

The parameter names a CMDB key (such as `key.name`) whose value determines whether filesystem
watching is enabled. It *should* be a boolean, but *may* be nil or any "truthy" value such as a
number or string. If the key is truthy, then the shim will perform filesystem-watching.

## Query the CMDB Directly

Ruby applications can access the CMDB as a Ruby proxy object:

    # Ready to use; no bootstrapping required.
    require 'cmdb'

    cmdb = CMDB::Interface.new
    cmdb.get('my_app.my_setting')
    cmdb.get('my_app.some_other_setting')

This allows you to read CMDB values from the directly from your code.

# Data Model

This library models all CMDBs as hierarchical key/value stores whose leaf nodes can be strings,
numbers, or arrays of like-typed objects. This model is a "least common denominator" simplification
of the data models of YML, JSON, ZooKeeper and etcd, allowing all of those technologies to be
treated as interchangeable sources of configuration information.

CMDB key names consist of a dot-separated string e.g. `my_app.category_of_settings.some_value`. The
value of a CMDB key can be a string, boolean, number, nil, or a list of any of those types.

CMDB keys *cannot* contain maps/hashes, nor can lists contain differently-typed data.

When a CMDB key is accessed through the Ruby API or referenced with a file-rewrite <<token>>, its
name always begins with the file or path name of its *source* (JSON file, consul path, etc).

When a CMDB key is written into the process environment or accessed via `Source#to_h`, its name
is "bare" and the source name is irrelevant.

If we use a `--consul-prefix` of `/kv/rightscale/intregration/shard403/common`
then a key names would look like `common.debug.enabled` and environment names
would look like `DEBUG_ENABLED`. The same is true if we load a `common.json`
file source from `/var/lib/cmdb`.

A future version of cmdb will harmonize the treatment of names; the prefix
will be insignificant to the key name and keys will look like environment
variables.

## Network Data Sources

To read from a consul server, pass `--consul-url` with a consul server address
and `--consul-prefix` one or more times with a top-level path to treat as a
named source.

## Disk-Based Data Sources

When the CMDB interface is initialized, it searches two directories for YAML files:
 - /var/lib/cmdb
 - ~/.cmdb

YAML files in these directories are assumed to contain CMDB values and loaded into memory in the
order they are encountered. The hierarchy of the YAML keys is flattened in order to derive
dot-separated key names. Consider the following YAML file:

    # beverages.yml
    coffee:
      - latte
      - cappucino
      - mocha
      - macchiato
    tea:
      - chai
      - herbal
      - black
    to_go: true

This defines three CMDB values: `beverages.coffee` (a list of four items), `beverages.tea`
(a list of three items), and `beverages.to_go` (a boolean).

### Key Namespaces

The name of a CMDB file is important; it defines a namespace for all of the variables contained
inside. No two files may share a name; therefore, no two CMDB keys can have the same name.
Likewise, all keys with a given prefix are guaranteed to come from the same source.

### Overlapping Namespaces

Because CMDB files can come from several directories, it's possible for two same-named data files
to define values in the same namespace. In this case, the behavior of RightService varies depending
on the value of RACK_ENV or RAILS_ENV:

  - unset, development or test: CMDB chooses the highest-precedence file and ignores the others
    after printing a warning. Files in `/etc` win over files in `$HOME`, which win over
    files in the working directory.

  - any other environment: CMDB fails with an error message that describes the problem and
    the locations of the overlapping files.

### Ambiguous Key Names

Consider a file that defines the following variables:

    # confusing.yml
    this:
      is:
        ambiguous
      was:
        very: ambiguous
        extremely: confusing

At first glance, ths file defines two CMDB keys:
  - `confusing.this.is` (a string)
  - `confusing.this.was` (a map)

However, an equally valid interpretation would be:
  - `confusing.this.is`
  - `confusing.this.was.very`
  - `confusing.this.was.extremely`

Because CMDB keys cannot contain maps, the first interpretation is wrong. The second
interpretation is valid according to the data model, but results in a situation where the type
of the keys could change if the structure of the YML file changes.

For this reason, any YAML file that defines an "ambiguous" key name will cause an error at
initialization time. To avoid ambiguous key names, think of your YAML file as a tree and remember
that _leaf nodes must define data_ and _internal nodes must define structure_.
