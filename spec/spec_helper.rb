require 'activerecord/mysql/reconnect'
require 'mysql2'

class Employee < ActiveRecord::Base; end

def mysql_start
  cmd = ENV['ACTIVERECORD_MYSQL_RECONNECT_MYSQL_START'] || 'sudo service mysql start'
  system("#{cmd} > /dev/null 2> /dev/null")
  puts "--- start mysql ---"
end

def mysql_stop
  cmd = ENV['ACTIVERECORD_MYSQL_RECONNECT_MYSQL_STOP'] || 'sudo service mysql stop'
  system("#{cmd} > /dev/null 2> /dev/null")
  puts "--- stop mysql ---"
end

def mysql_restart
  cmd = ENV['ACTIVERECORD_MYSQL_RECONNECT_MYSQL_RESTART'] || 'sudo killall -9 mysqld; sleep 3; sudo service mysql restart'
  system("#{cmd} > /dev/null 2> /dev/null")
  puts "--- restart mysql ---"
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
    expect(ActiveRecord::Base.enable_retry).to be_truthy
    ActiveRecord::Base.enable_retry = false
    yield
  ensure
    ActiveRecord::Base.enable_retry = true
  end
end

def enable_read_only
  begin
    expect(ActiveRecord::Base.retry_mode).to eq(:rw)
    ActiveRecord::Base.retry_mode = :r
    yield
  ensure
    ActiveRecord::Base.retry_mode = :rw
  end
end

def force_retry
  begin
    expect(ActiveRecord::Base.retry_mode).to eq(:rw)
    ActiveRecord::Base.retry_mode = :force
    yield
  ensure
    ActiveRecord::Base.retry_mode = :rw
  end
end

def retry_databases(dbs)
  begin
    expect(ActiveRecord::Base.retry_databases).to eq([])
    ActiveRecord::Base.retry_databases = dbs
    yield
  ensure
    ActiveRecord::Base.retry_databases = []
  end
end

def retry_giveup_count(n)
  retry_giveup_count_orig = ActiveRecord::Base.execution_tries

  begin
    ActiveRecord::Base.retry_giveup_count = n
    yield
  ensure
    ActiveRecord::Base.retry_giveup_count = retry_giveup_count_orig
  end
end

def execution_tries(n)
  execution_tries_orig = ActiveRecord::Base.execution_tries

  begin
    ActiveRecord::Base.execution_tries = n
    yield
  ensure
    ActiveRecord::Base.execution_tries = execution_tries_orig
  end
end

def thread_run
  thread_running = false
  do_stop = proc { thread_running = false }

  th = Thread.start {
    thread_running = true
    yield(do_stop)
    thread_running = false
  }

  th.abort_on_exception = true
  sleep 3
  expect(thread_running).to be_truthy

  return th
end

def lock_table
  Thread.start do
    begin
      ActiveRecord::Base.connection.execute("LOCK TABLES employees WRITE")
    rescue Exception
    end
  end

  sleep 3
end

RSpec.configure do |config|
  config.before(:all) do
    if ENV['ACTIVERECORD_MYSQL_RECONNECT_ENGINE']
      engine = ENV['ACTIVERECORD_MYSQL_RECONNECT_ENGINE']
      employees_sql = File.expand_path('../employees.sql', __FILE__)
      system("sed -i.bak '17s/ENGINE=[^ ]*/ENGINE=#{engine}/' #{employees_sql}")
    end
  end

  config.after(:all) do
    employees_sql = File.expand_path('../employees.sql', __FILE__)
    system("git checkout #{employees_sql}")
  end

  config.before(:each) do |context|
    desc = context.metadata[:full_description]
    puts <<-EOS


#{'#' * (desc.length + 4)}
# #{desc} #
#{'#' * (desc.length + 4)}

    EOS

    mysql_restart
    sleep 10
    ActiveRecord::Base.clear_all_connections!
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
    ActiveRecord::Base.retry_mode = :rw

    Activerecord::Mysql::Reconnect.reset_failure_count!
  end
end
