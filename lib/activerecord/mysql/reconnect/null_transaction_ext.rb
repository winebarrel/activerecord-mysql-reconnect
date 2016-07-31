module Activerecord::Mysql::Reconnect::NullTransactionExt
  def state
    nil
  end
end

class ActiveRecord::ConnectionAdapters::NullTransaction
  prepend Activerecord::Mysql::Reconnect::NullTransactionExt
end
