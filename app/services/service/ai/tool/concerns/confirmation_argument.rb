# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# The yes to a question Zammad asks before a change, for a client that cannot show its form: the user gives it in the
#   conversation, and the model calls again with an argument the client's own tool approval shows. MCP is never stricter
#   than the REST API with the same token, where the change needs no yes at all. A client that shows the form asks there,
#   and a no given there stays a no: the argument counts only where no form can be shown. Where the change overwrites
#   what someone wrote, the argument is the record's ID instead of true, so that only a model that saw the record gives it.
module Service::AI::Tool::Concerns::ConfirmationArgument
  extend ActiveSupport::Concern

  class_methods do
    # @param name [Symbol] the argument
    # @param action [String] what the user agrees to, completing "said yes to …"
    # @param id_of [String, nil] the record whose ID the argument takes, completing "The ID of …"; nil for true
    def confirmation_argument(name, action:, id_of: nil)
      # Written for the model, like every text a tool returns, so not translated.
      # rubocop:disable-next Zammad/DetectTranslatableString
      only = "Only for a client that cannot show Zammad's confirmation."
      return parameter name, type: :boolean, description: "true once the user said yes to #{action}, after an error named this argument. #{only}" if id_of.nil?

      parameter name, type: :integer, description: "The ID of #{id_of}, as a tool gave it, once the user said yes to #{action}. #{only}"
    end
  end

  private

  # @param value [true, Integer] what the argument has to be: true, or the ID of the record the change overwrites
  def confirmed_by_argument?(name, value: true)
    argument(name) == value && !confirmation.nil? && !confirmation_form?
  end

  def confirmation_form?
    confirmation.respond_to?(:form?) && confirmation.form?
  end

  # The sentence of a refusal that tells how the user says yes, where the client cannot show the form.
  #
  # @param action [String] what the user agrees to, completing "To …,"
  # @param value [true, Integer] what the argument has to be
  # @return [String, nil] nil where the client shows the form, or where no client asks
  def confirmation_argument_hint(name, action:, value: true)
    return if confirmation.nil? || confirmation_form?

    "To #{action}, ask the user, and only once they agree, call again with #{name}: #{value}."
  end
end
