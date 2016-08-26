FROM ruby:2-alpine
MAINTAINER Tony Spataro <tony@rightscale.com>

WORKDIR /cmdb
ENTRYPOINT ["bin/shell"]

# HACK: install runtime dependencies by hand in order to avoid depending on
# bundler + git + make + gcc at build time.
RUN gem install trollop -v '~> 2.0'

ADD bin /cmdb/bin/
ADD exe /cmdb/exe/
ADD lib /cmdb/lib/
