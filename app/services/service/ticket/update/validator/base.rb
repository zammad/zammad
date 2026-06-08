# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::Update::Validator::Base

  attr_reader :ticket, :ticket_data, :article_data, :macro

  def initialize(user: nil, ticket: nil, ticket_data: nil, article_data: nil, macro: nil)
    @user         = user
    @ticket       = ticket
    @ticket_data  = ticket_data
    @article_data = article_data
    @macro        = macro
  end

  def valid!
    raise NotImplementedError
  end
end
