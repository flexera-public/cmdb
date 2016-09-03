require 'docker/compose'

Given(%r{^a consul cluster at consul://consul$}) do
  docker_compose.up 'consul', detached: true
  sleep 1 # cheesy, but it works....
  @consul_started = true
end

Given(/^a consul key "([^"]*)" with value "([^"]*)"$/) do |key, value|
  m = Docker::Compose::Mapper.new(docker_compose)
  uri = m.map('consul://consul:8500')

  CMDB::Source.create(uri).instance_eval do
    path = ::File.join('/v1/kv/', @uri.path, key)
    http_put path, value
  end
end
