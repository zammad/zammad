# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Service::User::OutOfOffice < Service::Base
  attr_reader :user, :enabled, :start_at, :end_at, :replacement, :text

  def initialize(user, enabled:, start_at: nil, end_at: nil, replacement: nil, text: nil)
    super()

    @user        = user
    @enabled     = enabled
    @start_at    = start_at
    @end_at      = end_at
    @replacement = replacement
    @text        = text
  end

  def execute
    user.out_of_office                    = enabled
    user.out_of_office_start_at           = start_at
    user.out_of_office_end_at             = end_at
    user.out_of_office_replacement        = replacement
    user.preferences[:out_of_office_text] = text

    user.save!
  end
end
