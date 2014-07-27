describe 'activerecord-mysql-reconnect' do
  it 'select all' do
    expect {
      expect(Employee.all.length).to eq(300024)
      mysql_restart
      expect(Employee.all.length).to eq(300024)
    }.to_not raise_error
  end

  it 'count' do
    expect {
      expect(Employee.count).to eq(300024)
      mysql_restart
      expect(Employee.count).to eq(300024)
    }.to_not raise_error
  end

  it 'on select' do
    expect {
      th = thread_run {|do_stop|
        expect(Employee.where(:id => 1).pluck('sleep(10) * 0')).to eq([0])
      }

      mysql_restart
      expect(Employee.count).to be >= 300024
      th.join
    }.to_not raise_error
  end

  it 'on insert' do
    expect {
      th = thread_run {|do_stop|
        emp = nil

        mysql2_error('MySQL server has gone away') do
          emp = Employee.create(
                  :emp_no     => 1,
                  :birth_date => Time.now,
                  :first_name => "' + sleep(10) + '",
                  :last_name  => 'Tiger',
                  :hire_date  => Time.now
                )
        end

        do_stop.call

        expect(emp.id).to eq(300025)
        expect(emp.emp_no).to eq(1)
      }

      mysql_restart
      expect(Employee.count).to be >= 300024
      th.join
    }.to_not raise_error
  end

  [
    'MySQL server has gone away',
    'Server shutdown in progress',
    'closed MySQL connection',
    "Can't connect to MySQL server",
    'Query execution was interrupted',
    'Access denied for user',
    'The MySQL server is running with the --read-only option',
    "Can't connect to local MySQL server", # When running in local sandbox, or using a socket file
    'Unknown MySQL server host', # For DNS blips
    "Lost connection to MySQL server at 'reading initial communication packet'",
  ].each do |errmsg|
    it "on error: #{errmsg}" do
      expect {
        th = thread_run {|do_stop|
          emp = nil

          mysql2_error("x#{errmsg}x") do
            emp = Employee.create(
                    :emp_no     => 1,
                    :birth_date => Time.now,
                    :first_name => "' + sleep(10) + '",
                    :last_name  => 'Tiger',
                    :hire_date  => Time.now
                  )
          end

          do_stop.call

          expect(emp.id).to eq(300025)
          expect(emp.emp_no).to eq(1)
        }

        mysql_restart
        expect(Employee.count).to be >= 300024
        th.join
      }.to_not raise_error
    end
  end

  it "on unhandled error" do
    expect {
      th = thread_run {|do_stop|
        emp = nil

        mysql2_error("unhandled error") do
          emp = Employee.create(
                  :emp_no     => 1,
                  :birth_date => Time.now,
                  :first_name => "' + sleep(10) + '",
                  :last_name  => 'Tiger',
                  :hire_date  => Time.now
                )
        end

        do_stop.call

        expect(emp.id).to eq(300025)
        expect(emp.emp_no).to eq(1)
      }

      mysql_restart
      expect(Employee.count).to be >= 300024
      th.join
    }.to raise_error
  end

  it 'op update' do
    expect {
      th = thread_run {|do_stop|
        emp = Employee.where(:id => 1).first
        emp.first_name = "' + sleep(10) + '"
        emp.last_name = 'ZapZapZap'

        mysql2_error('MySQL server has gone away') do
          emp.save!
        end

        do_stop.call

        emp = Employee.where(:id => 1).first
        expect(emp.last_name).to eq('ZapZapZap')
      }

      mysql_restart
      expect(Employee.count).to eq(300024)
      th.join
    }.to_not raise_error
  end

  it 'without_retry' do
    expect {
      ActiveRecord::Base.without_retry do
        Employee.count
        mysql_restart
        Employee.count
      end
    }.to raise_error(ActiveRecord::StatementInvalid)
  end

  it 'transaction' do
    unless /MyISAM/i =~ ENV['ACTIVERECORD_MYSQL_RECONNECT_ENGINE']
      expect {
        expect(Employee.count).to eq(300024)

        mysql2_error('MySQL server has gone away') do
          ActiveRecord::Base.transaction do
            emp = Employee.create(
                    :emp_no     => 1,
                    :birth_date => Time.now,
                    :first_name => 'Scott',
                    :last_name  => 'Tiger',
                    :hire_date  => Time.now
                  )
            expect(emp.id).to eq(300025)
            expect(emp.emp_no).to eq(1)
            mysql_restart
            emp = Employee.create(
                    :emp_no     => 2,
                    :birth_date => Time.now,
                    :first_name => 'Scott',
                    :last_name  => 'Tiger',
                    :hire_date  => Time.now
                  )
            expect(emp.id).to eq(300025)
            expect(emp.emp_no).to eq(2)
          end
        end

        expect(Employee.count).to eq(300025)
      }.to_not raise_error
    end
  end

  it 'retryable_transaction' do
    unless /MyISAM/i =~ ENV['ACTIVERECORD_MYSQL_RECONNECT_ENGINE']
      expect {
        expect(Employee.count).to eq(300024)

        mysql2_error('MySQL server has gone away') do
          ActiveRecord::Base.retryable_transaction do
            emp = Employee.create(
                    :emp_no     => 1,
                    :birth_date => Time.now,
                    :first_name => 'Scott',
                    :last_name  => 'Tiger',
                    :hire_date  => Time.now
                  )
            expect(emp.id).to eq(300025)
            expect(emp.emp_no).to eq(1)
            mysql_restart
            emp = Employee.create(
                    :emp_no     => 2,
                    :birth_date => Time.now,
                    :first_name => 'Scott',
                    :last_name  => 'Tiger',
                    :hire_date  => Time.now
                  )
            expect(emp.id).to eq(300026)
            expect(emp.emp_no).to eq(2)
            mysql_restart
            emp = Employee.create(
                    :emp_no     => 3,
                    :birth_date => Time.now,
                    :first_name => 'Scott',
                    :last_name  => 'Tiger',
                    :hire_date  => Time.now
                  )
            expect(emp.id).to eq(300027)
            expect(emp.emp_no).to eq(3)
          end
        end

        expect(Employee.count).to eq(300027)
      }.to_not raise_error
    end
  end

  it 'retry new connection' do
    expect {
      ActiveRecord::Base.clear_all_connections!
      mysql_restart
      expect(Employee.count).to eq(300024)
    }.to_not raise_error
  end

  it 'retry verify' do
    expect {
      th = thread_run {|do_stop|
        mysql_stop
        sleep 10
        mysql_start
      }

      ActiveRecord::Base.connection.verify!
      th.join
    }.to_not raise_error
  end

  it 'retry reconnect' do
    expect {
      th = thread_run {|do_stop|
        mysql_stop
        sleep 10
        mysql_start
      }

      ActiveRecord::Base.connection.reconnect!
      th.join
    }.to_not raise_error
  end

  it 'disable reconnect' do
    disable_retry do
      expect {
        expect(Employee.all.length).to eq(300024)
        mysql_restart
        expect(Employee.all.length).to eq(300024)
      }.to raise_error(ActiveRecord::StatementInvalid)
    end

    expect {
      expect(Employee.all.length).to eq(300024)
      mysql_restart
      expect(Employee.all.length).to eq(300024)
    }.to_not raise_error
  end

  it 'read only (read)' do
    enable_read_only do
      expect {
        expect(Employee.all.length).to eq(300024)
        mysql_restart
        expect(Employee.all.length).to eq(300024)
      }.to_not raise_error
    end
  end

  it 'read only (write)' do
    enable_read_only do
      expect {
        lock_table

        th = thread_run {|do_stop|
          mysql2_error('MySQL server has gone away') do
            emp = Employee.create(
                    :emp_no     => 1,
                    :birth_date => Time.now,
                    :first_name => 'Scott',
                    :last_name  => 'Tiger',
                    :hire_date  => Time.now
                  )
          end
        }

        mysql_restart
        th.join
      }.to raise_error(ActiveRecord::StatementInvalid)
    end
  end

  it 'lost connection' do
    sql = "INSERT INTO `employees` (`birth_date`, `emp_no`, `first_name`, `hire_date`, `last_name`) VALUES ('2014-01-09 03:22:25', SLEEP(10), 'Scott', '2014-01-09 03:22:25', 'Tiger')"

    expect {
      ActiveRecord::Base.connection.execute(sql)
    }.to_not raise_error

    lock_table

    mysql2_error('Lost connection to MySQL server during query') do
      expect {
        th = thread_run {|do_stop|
          ActiveRecord::Base.connection.execute(sql)
        }

        sleep 3
        mysql_restart
        th.join
      }.to raise_error(ActiveRecord::StatementInvalid)
    end
  end

  it 'force retry' do
    sql = "INSERT INTO `employees` (`birth_date`, `emp_no`, `first_name`, `hire_date`, `last_name`) VALUES ('2014-01-09 03:22:25', 1, 'Scott', '2014-01-09 03:22:25', 'Tiger')"

    expect {
      ActiveRecord::Base.connection.execute(sql)
    }.to_not raise_error

    lock_table

    mysql2_error('Lost connection to MySQL server during query') do
      expect {
        th = thread_run {|do_stop|
          force_retry do
            ActiveRecord::Base.connection.execute(sql)
          end
        }

        mysql_restart
        th.join
      }.to_not raise_error
    end
  end

  it 'read-only=1' do
    mysql2_error('The MySQL server is running with the --read-only option so it cannot execute this statement:') do
      expect {
        expect(Employee.all.length).to eq(300024)
        mysql_restart
        expect(Employee.all.length).to eq(300024)
      }.to_not raise_error
    end
  end

  [
    :employees2,
    '127.0.0.2:employees',
    '127.0.0.\_:employees',
  ].each do |db|
    it "retry specific database: #{db}" do
      retry_databases(db) do
        expect {
          expect(Employee.all.length).to eq(300024)
          mysql_restart
          expect(Employee.all.length).to eq(300024)
        }.to raise_error(ActiveRecord::StatementInvalid)
      end

      expect {
        expect(Employee.all.length).to eq(300024)
        mysql_restart
        expect(Employee.all.length).to eq(300024)
      }.to_not raise_error
    end
  end

  [
    :employees,
    '127.0.0.1:employees',
    '127.0.0._:e%',
  ].each do |db|
    it "retry specific database: #{db}" do
      retry_databases(db) do
        expect {
          expect(Employee.all.length).to eq(300024)
          mysql_restart
          expect(Employee.all.length).to eq(300024)
        }.to_not raise_error
      end
    end
  end

  it 'give up' do
    retry_giveup_count(3) do
      mysql_stop

      3.times do
        expect {
          expect(Employee.all.length).to eq(300024)
        }.to raise_error
      end

      mysql_start
      sleep 10

      expect {
        expect(Employee.count).to eq(300024)
      }.to_not raise_error

      mysql_restart
      sleep 10

      expect {
        expect(Employee.all.length).to eq(300024)
      }.to raise_error
    end
  end

  it 'not give up' do
    retry_giveup_count(3) do
      execution_tries(2) do
        3.times do
          p 1
          mysql_stop

          2.times do
            expect {
              expect(Employee.all.length).to eq(300024)
            }.to raise_error
          end
          p 2

          mysql_start
          sleep 10

          expect {
            expect(Employee.count).to eq(300024)
          }.to_not raise_error

          p 3
          mysql_restart
          sleep 10

          expect {
            expect(Employee.all.length).to eq(300024)
          }.to_not raise_error
        end
      end
    end
  end
end
