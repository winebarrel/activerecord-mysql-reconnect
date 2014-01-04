require 'active_record'
require 'active_record/base'
require 'active_support'
require 'activerecord/mysql/reconnect/abstract_mysql_adapter_ext'

class ActiveRecord::Base
  class_attribute :execution_tries
  class_attribute :execution_retry_wait

  class << self
    def without_retry
      begin
        Thread.current[ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter::WITHOUT_RETRY_KEY] = true
        yield
      ensure
        Thread.current[ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter::WITHOUT_RETRY_KEY] = nil
      end
    end

    def retryable_transaction
      begin
        Thread.current[ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter::RETRYABLE_TRANSACTION_KEY] = []

        ActiveRecord::Base.transaction do
          yield
        end
      ensure
        Thread.current[ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter::RETRYABLE_TRANSACTION_KEY] = nil
      end
    end
  end
end
