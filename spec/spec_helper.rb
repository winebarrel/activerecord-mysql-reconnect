require 'activerecord/mysql/reconnect'

class Employee < ActiveRecord::Base; end

def mysql_restart
  cmd = ENV['ACTIVERECORD_MYSQL_RECONNECT_MYSQL_RESTART'] || 'sudo /etc/init.d/mysql restart'
  system(cmd)
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
    ActiveRecord::Base.execution_tries = 10
  end
end
