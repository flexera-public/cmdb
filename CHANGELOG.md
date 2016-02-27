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
