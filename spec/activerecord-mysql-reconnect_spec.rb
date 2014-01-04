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
      thread_running = false

      th = Thread.start {
        thread_running = true
        expect(Employee.where(:id => 1).pluck('sleep(15)')).to eq([1])
        thread_running = false
      }

      th.abort_on_exception = true
      sleep 3
      expect(thread_running).to be_true
      mysql_restart
      expect(Employee.count).to be >= 300024
      th.join
    }.to_not raise_error
  end

  it 'on insert' do
    expect {
      thread_running = false

      th = Thread.start {
        thread_running = true
        emp = Employee.create(
                :emp_no     => 1,
                :birth_date => Time.now,
                :first_name => "' + sleep(15) + '",
                :last_name  => 'Tiger',
                :hire_date  => Time.now
              )
        thread_running = false
        expect(emp.id).to eq(300025)
        expect(emp.emp_no).to eq(1)
      }

      th.abort_on_exception = true
      sleep 3
      expect(thread_running).to be_true
      mysql_restart
      expect(Employee.count).to be >= 300024
      th.join
    }.to_not raise_error
  end

  it 'op update' do
    expect {
      thread_running = false

      th = Thread.start {
        thread_running = true
        emp = Employee.where(:id => 1).first
        emp.first_name = "' + sleep(15) + '"
        emp.last_name = 'ZapZapZap'
        emp.save!
        thread_running = false

        emp = Employee.where(:id => 1).first
        expect(emp.last_name).to eq('ZapZapZap')
      }

      th.abort_on_exception = true
      sleep 3
      expect(thread_running).to be_true
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
    expect {
      expect(Employee.count).to eq(300024)

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

      expect(Employee.count).to eq(300025)
    }.to_not raise_error
  end

  it 'retryable_transaction' do
    expect {
      expect(Employee.count).to eq(300024)

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

      expect(Employee.count).to eq(300027)
    }.to_not raise_error
  end
end
