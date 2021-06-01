# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class Transaction
  attr_reader :options
  attr_accessor :original_user_id, :original_interface_handle

  def initialize(options = {})
    @options = options
  end

  def execute
    start_execute

    ActiveRecord::Base.transaction do
      start_transaction

      yield
    ensure
      finish_transaction
    end
  ensure
    finish_execute
  end

  def self.execute(options = {}, &block)
    Transaction.new(options).execute(&block)
  end

  private

  def start_execute
    reset_user_id_start
    bulk_import_start
    interface_handle_start
  end

  def start_transaction
    PushMessages.init
  end

  def finish_execute
    reset_user_id_finish
    bulk_import_finish
  end

  def finish_transaction
    interface_handle_finish

    TransactionDispatcher.commit(options)
    PushMessages.finish
  end

  def reset_user_id?
    options[:reset_user_id] == true
  end

  def reset_user_id_start
    return if !reset_user_id?

    self.original_user_id = UserInfo.current_user_id

    UserInfo.current_user_id = 1
  end

  def reset_user_id_finish
    return if !reset_user_id?

    UserInfo.current_user_id = original_user_id
  end

  def bulk_import?
    options[:bulk] == true
  end

  def bulk_import_start
    return if !bulk_import?

    BulkImportInfo.enable
  end

  def bulk_import_finish
    return if !bulk_import?

    BulkImportInfo.disable
  end

  def interface_handle?
    options[:interface_handle].present?
  end

  def interface_handle_start
    return if !interface_handle?

    self.original_interface_handle = ApplicationHandleInfo.current

    ApplicationHandleInfo.current = options[:interface_handle]
  end

  def interface_handle_finish
    return if !interface_handle?

    ApplicationHandleInfo.current = original_interface_handle
  end
end
