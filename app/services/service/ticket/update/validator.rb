# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::Update::Validator
  include Mixin::RequiredSubPaths

  def self.exceptions
    BaseError.descendants
  end

  attr_reader :user, :ticket, :ticket_data, :article_data, :skip_validators

  def initialize(user:, ticket:, ticket_data:, article_data:, skip_validators:)
    @user             = user
    @ticket           = ticket
    @ticket_data      = ticket_data
    @article_data     = article_data
    @skip_validators  = skip_validators
  end

  def validate!
    validators.each do |validator|
      validator.new(
        user:         user,
        ticket:       ticket,
        ticket_data:  ticket_data,
        article_data: article_data,
      ).valid!
    end
  end

  private

  def validators
    Service::Ticket::Update::Validator::Base.descendants.reject do |klass|
      skip_validators&.any? { |validator| validator.name.starts_with?(klass.name) }
    end
  end
end
