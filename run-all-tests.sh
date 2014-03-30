#!/bin/bash
set -e

# sysvbanner
# https://github.com/uffejakobsen/sysvbanner

banner `mysqld --version`

export ACTIVERECORD_MYSQL_RECONNECT_ENGINE=InnoDB
banner $ACTIVERECORD_MYSQL_RECONNECT_ENGINE

sed -i.bak "s/spec.add_dependency 'activerecord'.*/spec.add_dependency 'activerecord', '= 3.2.14'/" activerecord-mysql-reconnect.gemspec
bundle install -j4
banner `bundle exec ruby -e 'require "active_record"; puts ActiveRecord::VERSION::STRING'`
bundle exec rake

sed -i.bak "s/spec.add_dependency 'activerecord'.*/spec.add_dependency 'activerecord', '~> 3.2.14'/" activerecord-mysql-reconnect.gemspec
bundle install -j4
banner `bundle exec ruby -e 'require "active_record"; puts ActiveRecord::VERSION::STRING'`
bundle exec rake

sed -i.bak "s/spec.add_dependency 'activerecord'.*/spec.add_dependency 'activerecord', '~> 4.0'/" activerecord-mysql-reconnect.gemspec
bundle install -j4
banner `bundle exec ruby -e 'require "active_record"; puts ActiveRecord::VERSION::STRING'`
bundle exec rake

export ACTIVERECORD_MYSQL_RECONNECT_ENGINE=MyISAM
banner $ACTIVERECORD_MYSQL_RECONNECT_ENGINE

sed -i.bak "s/spec.add_dependency 'activerecord'.*/spec.add_dependency 'activerecord', '= 3.2.14'/" activerecord-mysql-reconnect.gemspec
bundle install -j4
banner `bundle exec ruby -e 'require "active_record"; puts ActiveRecord::VERSION::STRING'`
bundle exec rake

sed -i.bak "s/spec.add_dependency 'activerecord'.*/spec.add_dependency 'activerecord', '~> 3.2.14'/" activerecord-mysql-reconnect.gemspec
bundle install -j4
banner `bundle exec ruby -e 'require "active_record"; puts ActiveRecord::VERSION::STRING'`
bundle exec rake

sed -i.bak "s/spec.add_dependency 'activerecord'.*/spec.add_dependency 'activerecord', '~> 4.0'/" activerecord-mysql-reconnect.gemspec
bundle install -j4
banner `bundle exec ruby -e 'require "active_record"; puts ActiveRecord::VERSION::STRING'`
bundle exec rake

git checkout activerecord-mysql-reconnect.gemspec
