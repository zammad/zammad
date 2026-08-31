# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Checks that would make a save destroy somebody else's work, in the "warn, then let the user
#   proceed" shape Service::Ticket::Update::Validator established: each validator raises a
#   BaseError, the mutation turns it into a user error the client can recognise, and the client may
#   resubmit with that exception in `skip_validators`.
class Service::KnowledgeBase::Answer::Update::Validator < Service::Base
  include Mixin::RequiredSubPaths

  requires_current_user!

  def self.exceptions
    BaseError.descendants
  end

  attr_reader :answer, :answer_data, :kb_locale, :skip_validators

  def initialize(answer:, answer_data:, kb_locale:, skip_validators: nil)
    @answer          = answer
    @answer_data     = answer_data
    @kb_locale       = kb_locale
    @skip_validators = skip_validators
  end

  def execute
    validators.each do |validator|
      validator.new(
        user:        current_user,
        answer:      answer,
        answer_data: answer_data,
        kb_locale:   kb_locale,
      ).valid!
    end
  end

  private

  def validators
    Service::KnowledgeBase::Answer::Update::Validator::Base.descendants.reject do |klass|
      skip_validators&.any? { |validator| validator.name.starts_with?(klass.name) }
    end
  end
end
