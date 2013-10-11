# Activerecord::Mysql::Reconnect

It is the library to reconnect automatically when ActiveRecord is disconnected from MySQL.

## Installation

Add this line to your application's Gemfile:

    gem 'activerecord-mysql-reconnect'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install activerecord-mysql-reconnect

## Usage

```ruby
#!/usr/bin/env ruby
require 'active_record'
require 'activerecord/mysql/reconnect'
require 'logger'

ActiveRecord::Base.establish_connection(
  adapter:  'mysql2',
  host:     '127.0.0.1',
  username: 'root',
  database: 'test',
)

ActiveRecord::Base.logger = Logger.new($stdout)
ActiveRecord::Base.execution_tries = 3

class Employee < ActiveRecord::Base; end

p Employee.count
system('sudo /etc/init.d/mysqld restart')
p Employee.count
```

```
shell> ruby test.rb
D, [2013-10-11T08:48:16.792176 #16191] DEBUG -- :    (65.7ms)  SELECT COUNT(*) FROM `employees`
300024
Stopping mysqld:                                           [  OK  ]
Starting mysqld:                                           [  OK  ]
D, [2013-10-11T08:48:22.986682 #16191] DEBUG -- :    (0.4ms)  SELECT COUNT(*) FROM `employees`
D, [2013-10-11T08:48:22.986897 #16191] DEBUG -- : Mysql2::Error: MySQL server has gone away: SELECT COUNT(*) FROM `employees`
W, [2013-10-11T08:48:22.987166 #16191]  WARN -- : MySQL server has gone away. Trying to reconnect in 0.5 seconds.
D, [2013-10-11T08:48:23.588412 #16191] DEBUG -- :    (99.4ms)  SELECT COUNT(*) FROM `employees`
300024
```
