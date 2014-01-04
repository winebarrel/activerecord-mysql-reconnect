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
    tries = Activerecord::Mysql::Reconnect.execution_tries
    logger = Activerecord::Mysql::Reconnect.logger
    block_with_reconnect = nil
    retval = nil
    sql_names = [[sql, name]]
    orig_transaction = @transaction

    retryable_loop(tries) do |n|
      begin
        retval = (block_with_reconnect || block).call(sql_names)
        break
      rescue => e
        if (tries.zero? or n < tries) and Activerecord::Mysql::Reconnect.should_handle?(e)
          unless block_with_reconnect
            block_with_reconnect = proc do |i|
              reconnect!
              @transaction = orig_transaction if orig_transaction
              block.call(i)
            end
          end

          sql_names = merge_transaction(sql, name)
          wait = Activerecord::Mysql::Reconnect.execution_retry_wait * n
          logger.warn("MySQL server has gone away. Trying to reconnect in #{wait} seconds. (cause: #{e} [#{e.class}])")
          sleep(wait)

          next
        else
          raise e
        end
      end
    end

    return retval
  end

  def retryable_loop(n)
    if n.zero?
      loop { n += 1 ; yield(n) }
    else
      n.times {|i| yield(i + 1) }
    end
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
