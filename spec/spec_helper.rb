require 'activerecord/mysql/reconnect'

class Employee < ActiveRecord::Base; end

RSpec.configure do |config|
  config.before(:all) do
    employees_sql = File.expand_path('../employees.sql', __FILE__)
    system("mysql -u root < #{employees_sql}")

    ActiveRecord::Base.establish_connection(
      :adapter  => 'mysql2',
      :host     => '127.0.0.1',
      :username => 'root',
      :database => 'employees'
    )
  end
end
