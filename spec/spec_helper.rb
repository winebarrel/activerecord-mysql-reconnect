RSpec.configure do |config|
  config.before(:all) do
    employees_sql = File.expand_path('../employees.sql', __FILE__)
    system("mysql -u root < #{employees_sql}")
  end
end
