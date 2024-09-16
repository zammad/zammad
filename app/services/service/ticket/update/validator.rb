# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::Update::Validator
  include Mixin::RequiredSubPaths

  attr_reader :user, :ticket, :ticket_data, :article_data, :skip_validator

  def initialize(user:, ticket:, ticket_data:, article_data:, skip_validator:)
    @user           = user
    @ticket         = ticket
    @ticket_data    = ticket_data
    @article_data   = article_data
    @skip_validator = skip_validator
  end

  def validate!
    validators.each do |validator|
      validator.new(
        user:         user,
        ticket:       ticket,
        ticket_data:  ticket_data,
        article_data: article_data,
      ).validate!
    end
  end

  private

  def validators
    Service::Ticket::Update::Validator::Base
      .descendants
      .reject { |klass| skip_validator&.starts_with?(klass.name) }
  end
end
