# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::Update::Validator::Base

  attr_reader :ticket, :ticket_data, :article_data

  def initialize(user:, ticket:, ticket_data:, article_data:)
    @user         = user
    @ticket       = ticket
    @ticket_data  = ticket_data
    @article_data = article_data
  end

  def validate!
    raise NotImplementedError
  end
end
