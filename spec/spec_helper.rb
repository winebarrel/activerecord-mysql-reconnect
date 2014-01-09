require 'activerecord/mysql/reconnect'
require 'mysql2'

class Employee < ActiveRecord::Base; end

def mysql_start
  cmd = ENV['ACTIVERECORD_MYSQL_RECONNECT_MYSQL_START'] || 'sudo /etc/init.d/mysql start'
  system(cmd)
end

def mysql_stop
  cmd = ENV['ACTIVERECORD_MYSQL_RECONNECT_MYSQL_STOP'] || 'sudo /etc/init.d/mysql stop'
  system(cmd)
end

def mysql_restart
  cmd = ENV['ACTIVERECORD_MYSQL_RECONNECT_MYSQL_RESTART'] || 'sudo killall -9 mysqld; sleep 3; sudo /etc/init.d/mysql restart; true'
  system(cmd)
end

class Mysql2::Client
  def escape(str); str; end
end

class Mysql2::Error
  def message
    $mysql2_error_message || super
  end
end

def mysql2_error(message)
  begin
    $mysql2_error_message = message
    yield
  ensure
    $mysql2_error_message = nil
  end
end

def disable_retry
  begin
    expect(ActiveRecord::Base.enable_retry).to be_true
    ActiveRecord::Base.enable_retry = false
    yield
  ensure
    ActiveRecord::Base.enable_retry = true
  end
end

def enable_read_only
  begin
    expect(ActiveRecord::Base.retry_read_only).to be_false
    ActiveRecord::Base.retry_read_only = true
    yield
  ensure
    ActiveRecord::Base.retry_read_only = false
  end
end

RSpec.configure do |config|
  config.before(:each) do
    employees_sql = File.expand_path('../employees.sql', __FILE__)
    system("mysql -u root < #{employees_sql}")

    ActiveRecord::Base.establish_connection(
      :adapter  => 'mysql2',
      :host     => '127.0.0.1',
      :username => 'root',
      :database => 'employees'
    )

    ActiveRecord::Base.logger = Logger.new($stdout)
    ActiveRecord::Base.logger.formatter = proc {|_, _, _, message| "#{message}\n" }
    ActiveRecord::Base.enable_retry = true
    ActiveRecord::Base.execution_tries = 10
    ActiveRecord::Base.retry_read_only = false
  end
end
