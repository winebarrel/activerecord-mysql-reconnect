require 'mysql2'

class MysqlServer
  CLI_ARGS = '-u root -P 3306 -h 127.0.0.1'
  REDIRECT_TO_DEV_NULL = ENV['DEBUG'] == '1' ? '' : '> /dev/null 2> /dev/null'

  class << self
    def setup
      clean
      system('mkdir -p /tmp/mysql_for_ar_mysql_reconn')
    end

    def start
      system("docker-compose up -d #{REDIRECT_TO_DEV_NULL}")
      wait_mysql_start
    end

    def stop
      system("docker-compose stop #{REDIRECT_TO_DEV_NULL}")
    end

    def restart
      stop
      start
    end

    def wait_mysql_start
      started = false

      60.times do
        break if (started = ping.success?)
        sleep 1
      end

      unless started
        raise 'cannot start mysql server'
      end
    end

    def ping
      system("mysqladmin ping #{CLI_ARGS} #{REDIRECT_TO_DEV_NULL}")
      $?
    end

    def clean
      stop

      if ENV['SKIP_CLEAN_DATA'] != '1'
        system("docker-compose rm -f mysql_for_ar_mysql_reconn #{REDIRECT_TO_DEV_NULL}")
        system('rm -rf /tmp/mysql_for_ar_mysql_reconn')
      end
    end

    def reset
      reset_database
      reset_table
      reset_data
    end

    def reset_database
      system("mysql #{CLI_ARGS} -e 'DROP DATABASE IF EXISTS employees' #{REDIRECT_TO_DEV_NULL}")
      system("mysql #{CLI_ARGS} -e 'CREATE DATABASE employees' #{REDIRECT_TO_DEV_NULL}")
    end

    def reset_table
      engine = ENV['ACTIVERECORD_MYSQL_RECONNECT_ENGINE'] || 'InnoDB'
      system("mysql #{CLI_ARGS} employees -e 'DROP TABLE IF EXISTS employees' #{REDIRECT_TO_DEV_NULL}")

      create_table_sql = <<-SQL.gsub(/\n/, '')
        CREATE TABLE `employees` (
          `id` int(11) NOT NULL AUTO_INCREMENT,
          `emp_no` int(11) NOT NULL,
          `birth_date` date NOT NULL,
          `first_name` varchar(14) NOT NULL,
          `last_name` varchar(16) NOT NULL,
          `hire_date` date NOT NULL,
          PRIMARY KEY (`id`)
        ) ENGINE=#{engine}
      SQL

      system("mysql #{CLI_ARGS} employees -e '#{create_table_sql}' #{REDIRECT_TO_DEV_NULL}")
    end

    def reset_data
      data_file = File.expand_path('../data.sql', __FILE__)
      system("mysql #{CLI_ARGS} employees < #{data_file} #{REDIRECT_TO_DEV_NULL}")
    end

    def lock_tables
      data_file = File.expand_path('../data.sql', __FILE__)
      system("mysql #{CLI_ARGS} employees -e 'LOCK TABLES employees WRITE; SELECT SLEEP(60)' #{REDIRECT_TO_DEV_NULL}")
    end
  end # of class methods
end
