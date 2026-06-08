# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::Ticket::Update::Validator < Service::Base
  include Mixin::RequiredSubPaths

  requires_current_user!

  def self.exceptions
    BaseError.descendants
  end

  attr_reader :ticket, :ticket_data, :article_data, :skip_validators, :macro

  def initialize(ticket:, ticket_data:, article_data:, skip_validators:, macro: nil)

    @ticket           = ticket
    @ticket_data      = ticket_data
    @article_data     = article_data
    @skip_validators  = skip_validators
    @macro            = macro
  end

  def execute
    validators.each do |validator|
      validator.new(
        user:         current_user,
        ticket:,
        ticket_data:,
        article_data:,
        macro:,
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
