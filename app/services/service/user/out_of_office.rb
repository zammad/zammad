# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::User::OutOfOffice < Service::Base
  requires_current_user!

  attr_reader :enabled, :start_at, :end_at, :replacement, :text

  def initialize(enabled:, start_at: nil, end_at: nil, replacement: nil, text: nil)
    @enabled     = enabled
    @start_at    = start_at
    @end_at      = end_at
    @replacement = replacement
    @text        = text
  end

  def execute
    current_user.out_of_office                    = enabled
    current_user.out_of_office_start_at           = start_at
    current_user.out_of_office_end_at             = end_at
    current_user.out_of_office_replacement        = replacement
    current_user.preferences[:out_of_office_text] = text

    current_user.save!
  end
end
