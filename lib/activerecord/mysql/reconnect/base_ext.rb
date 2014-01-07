class ActiveRecord::Base
  class_attribute :execution_tries, :instance_writer => false
  class_attribute :execution_retry_wait, :instance_writer => false
  class_attribute :enable_retry, :instance_writer => false

  class << self
    def without_retry
      Activerecord::Mysql::Reconnect.without_retry do
        yield
      end
    end

    def retryable_transaction
      Activerecord::Mysql::Reconnect.retryable_transaction do
        yield
      end
    end
  end
end
