# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::Bulk::SingleItemUpdate < Service::Base
  attr_reader :user, :ticket, :perform

  class BulkSingleError < StandardError
    attr_reader :record, :original_error

    def initialize(record:, original_error:)
      @record         = record
      @original_error = original_error

      super(original_error.message)
    end

    def failed_ticket
      @record
    end
  end

  def initialize(user:, ticket:, perform:)
    @user    = user
    @ticket  = ticket
    @perform = perform

    super()
  end

  def execute
    error = nil

    ActiveRecord::Base.transaction do
      Pundit.authorize(user, ticket, :agent_update_access?)

      UserInfo.with_user_id(user.id) do
        Service::Ticket::Update
          .new(current_user: user)
          .execute(ticket:, ticket_data:, macro:, skip_validators: Service::Ticket::Update::Validator.exceptions)
      end
    rescue => e
      error = BulkSingleError.new(record: ticket, original_error: e)

      raise ActiveRecord::Rollback
    end

    raise error if error

    true
  end

  private

  def ticket_data
    return {} if perform[:input].blank?

    # Deep cloning preserving ActiveRecord object IDs.
    # Service::Ticket::Update and Service::Ticket::Article::Create are mutating the input data in place.
    # A new instance of the input data is needed for each loop run.
    # DO NOT MEMOIZE THIS
    Marshal.load(Marshal.dump(perform[:input]))
  end

  def macro
    perform[:macro]
  end
end
