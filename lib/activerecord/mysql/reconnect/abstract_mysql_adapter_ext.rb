class ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter
  def execute_with_reconnect(sql, name = nil)
    retryable(sql, name) do |sql_names|
      retval = nil

      sql_names.each do |s, n|
        retval = execute_without_reconnect(s, n)
      end

      add_sql_to_transaction(sql, name)
      retval
    end
  end

  alias_method_chain :execute, :reconnect

  private

  def retryable(sql, name, &block)
    block_with_reconnect = nil
    sql_names = [[sql, name]]
    orig_transaction = @transaction

    Activerecord::Mysql::Reconnect.retryable(
      :proc => proc {
        (block_with_reconnect || block).call(sql_names)
      },
      :on_error => proc {
        unless block_with_reconnect
          block_with_reconnect = proc do |i|
            reconnect_without_retry!
            @transaction = orig_transaction if orig_transaction
            block.call(i)
          end
        end

        sql_names = merge_transaction(sql, name)
      },
      :sql => sql,
      :read_only => Activerecord::Mysql::Reconnect.retry_read_only
    )
  end

  def add_sql_to_transaction(sql, name)
    if (buf = Activerecord::Mysql::Reconnect.retryable_transaction_buffer)
      buf << [sql, name]
    end
  end

  def merge_transaction(sql, name)
    sql_name = [sql, name]

    if (buf = Activerecord::Mysql::Reconnect.retryable_transaction_buffer)
      buf + [sql_name]
    else
      [sql_name]
    end
  end
end
