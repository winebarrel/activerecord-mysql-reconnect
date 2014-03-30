class ActiveRecord::Base
  class_attribute :execution_tries,      :instance_accessor => false
  class_attribute :execution_retry_wait, :instance_accessor => false
  class_attribute :enable_retry,         :instance_accessor => false

  RETRY_MODES = [:r, :rw, :force]
  DEFAULT_RETRY_MODE = :r

  class << self
    def retry_mode=(v)
       Activerecord::Mysql::Reconnect.retry_mode = v
    end

    def retry_mode
       Activerecord::Mysql::Reconnect.retry_mode
    end

    def retry_databases=(v)
       Activerecord::Mysql::Reconnect.retry_databases = v
    end

    def retry_databases
       Activerecord::Mysql::Reconnect.retry_databases
    end

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
