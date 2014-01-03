describe Hash do
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
      th = Thread.start {
        expect(Employee.where(:id => 1).pluck('sleep(15)')).to eq([1])
      }

      th.abort_on_exception = true
      sleep 3

      mysql_restart
      expect(Employee.count).to eq(300024)
      th.join
    }.to_not raise_error
  end
end
