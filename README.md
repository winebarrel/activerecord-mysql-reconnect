# activerecord-mysql-reconnect

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
ActiveRecord::Base.logger.formatter = proc {|_, _, _, message| "#{message}\n" }
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
MySQL server has gone away. Trying to reconnect in 0.5 seconds.
   (101.5ms)  SELECT COUNT(*) FROM `employees`
300024
```

## Link

* [RubyGems.org site](http://rubygems.org/gems/activerecord-mysql-reconnect)
