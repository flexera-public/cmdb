v3
==

Remove `--env` option and make it the default behavior

Get rid of namespace prefix from canonical CMDB key names

Redo `--consul-xxx` flags. Generalize as a new `--source` param inspired by
docker-swarm discovery URLs, that lets one specify:
  - a consul URL (consul://) + prefix
  - a JSON, YAML or .env file (file://)
  - someday an etcd (etcd://) or zookeeper (zk://) URL + prefix
Respect ordering of sources as specified on command line.

Remove `--reload` and `--reload-signal flags`.

Add `--disjoint` flag & stop ensuring disjoint sources by default

Transform `--dir` into `--rewrite`

Add `.cmdb/config` file option

Actually respect the `--quiet` flag
