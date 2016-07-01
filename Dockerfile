FROM ruby:2.2
MAINTAINER Tony Spataro <tony@rightscale.com>

WORKDIR /cmdb
CMD bin/console

ADD lib/cmdb/version.rb /cmdb/lib/cmdb/version.rb
ADD cmdb.gemspec /cmdb/
ADD .git /cmdb/.git/
ADD Gemfile* /cmdb/
RUN bundle install
ADD exe /cmdb/exe/
ADD bin /cmdb/bin/
ADD lib /cmdb/lib/
