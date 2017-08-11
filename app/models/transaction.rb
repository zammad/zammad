class Transaction
  def self.execute(options = {})
    if options[:reset_user_id] == true
      UserInfo.current_user_id = 1
    end
    original_interface_handle = ApplicationHandleInfo.current
    if options[:interface_handle]
      ApplicationHandleInfo.current = options[:interface_handle]
    end
    ActiveRecord::Base.transaction do
      begin
        PushMessages.init
        yield
        if options[:interface_handle]
          ApplicationHandleInfo.current = original_interface_handle
        end
        Observer::Transaction.commit(
          disable_notification: options[:disable_notification],
          disable: options[:disable],
        )
        PushMessages.finish
      rescue ActiveRecord::StatementInvalid => e
        Rails.logger.error e.inspect
        Rails.logger.error e.backtrace
        raise ActiveRecord::Rollback
      end
    end
  end
end
