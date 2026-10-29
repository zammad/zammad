# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::ApplyValue::UserAutocomplete < FormUpdater::ApplyValue::Base

  # Resolves a User id into the canonical option entry consumed by the
  # autocomplete FormKit field — same shape `FieldCustomer`/`FieldAgent` build
  # client-side. Reused by `map_value` for top-level form fields, by the
  # advanced search filter prefill path and by the ticket create prefill.
  #
  # Only users of the current user's policy scope, not those visible in part: the
  # label falls back to the email address or the login, which a field scope hides.
  def self.resolve_option(id, current_user:)
    # Cast to an integer, a string like '12abc' would hit user 12.
    return if !id.to_s.match?(%r{\A\d+\z})

    user = Pundit.policy_scope!(current_user, User).find_by(id: id)
    return if !user

    {
      value:   user.id,
      label:   user.fullname.presence || user.login,
      heading: user.organization&.name,
      object:  FormUpdater::Graphql::Serializers::User.serialize(user, current_user:),
    }
  end

  def can_handle_field?(field:, field_attribute:)
    field_attribute&.data_option&.[]('relation') == 'User'
  end

  def map_value(field:, config:)
    option = self.class.resolve_option(config['value'], current_user: context[:current_user])
    return if !option

    result[field][:value] = option[:value]
    result[field][:options] = [option]
  end
end
