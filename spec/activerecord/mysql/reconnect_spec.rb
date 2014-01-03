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
end
