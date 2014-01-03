describe Hash do
  it 'count' do
    expect(Employee.count).to eq(300024)
    mysql_restart
    expect(Employee.count).to eq(300024)
  end
end
