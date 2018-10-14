# activerecord-mysql-reconnect

It is the library to reconnect automatically when ActiveRecord is disconnected from MySQL.

[![Gem Version](https://badge.fury.io/rb/activerecord-mysql-reconnect.svg)](http://badge.fury.io/rb/activerecord-mysql-reconnect)
[![Build Status](https://travis-ci.org/winebarrel/activerecord-mysql-reconnect.svg?branch=master)](https://travis-ci.org/winebarrel/activerecord-mysql-reconnect)

## Installation

Add this line to your application's Gemfile:

    gem 'activerecord-mysql-reconnect'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install activerecord-mysql-reconnect

## Usage

```ruby
require 'active_record'
require 'activerecord-mysql-reconnect'
require 'logger'

ActiveRecord::Base.establish_connection(
  adapter:  'mysql2',
  host:     '127.0.0.1',
  username: 'root',
  database: 'employees',
)

ActiveRecord::Base.logger = Logger.new($stdout)
ActiveRecord::Base.logger.formatter = proc {|_, _, _, message| "#{message}\n" }
ActiveRecord::Base.enable_retry = true
ActiveRecord::Base.execution_tries = 3

class Employee < ActiveRecord::Base; end

p Employee.count
system('sudo /etc/init.d/mysqld restart')
p Employee.count
```

```
shell> ruby test.rb
   (64.1ms)  SELECT COUNT(*) FROM `employees`
300024
Stopping mysqld:                                           [  OK  ]
Starting mysqld:                                           [  OK  ]
   (0.4ms)  SELECT COUNT(*) FROM `employees`
Mysql2::Error: MySQL server has gone away: SELECT COUNT(*) FROM `employees`
MySQL server has gone away. Trying to reconnect in 0.5 seconds. (cause: Mysql2::Error: MySQL server has gone away: SELECT COUNT(*) FROM `employees` [ActiveRecord::StatementInvalid], connection: host=127.0.0.1;database=employees;username=root)
   (101.5ms)  SELECT COUNT(*) FROM `employees`
300024
```

### without_retry

```ruby
ActiveRecord::Base.without_retry do
  Employee.count
end
```

### Add a retry error message

```ruby
Activerecord::Mysql::Reconnect.handle_rw_error_messages.update(
  zapzapzap: 'ZapZapZap'
)
# or `Activerecord::Mysql::Reconnect.handle_r_error_messages...`
```

## Use on rails

### Gemfile

```ruby
gem 'activerecord-mysql-reconnect'
```

### environment file

```ruby
MyApp::Application.configure do
  ...
  config.active_record.enable_retry = true
  #config.active_record.retry_databases = :employees
  # e.g. [:employees]
  #      ['employees', 'localhost:test', '192.168.1.1:users']
  #      ['192.168.%:emp\_all']
  #      ['emp%']
  # retry_databases -> nil: retry all databases (default)
  config.active_record.execution_tries = 10 # times
  # execution_tries -> 0: retry indefinitely
  config.active_record.execution_retry_wait = 1.5 # sec
  config.active_record.retry_mode = :rw # default: `:r`, valid values: `:r`, `:rw`, `:force`
  ...
ene
```

## Retry mode

* `:r`      Retry only SELECT / SHOW / SET
* `:rw`     Retry in all SQL, but does not retry if `Lost connection` has happened in write SQL
* `:force`  Retry in all SQL

## Running tests

It requires the following:

* Docker
* Docker Compose

```sh
bundle install
bundle exec appraisal install
bundle exec appraisal activerecord-4.2 rake
bundle exec appraisal activerecord-5.0 rake
```
