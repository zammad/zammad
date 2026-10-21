# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::ApplyValue::OrganizationAutocomplete < FormUpdater::ApplyValue::Base

  # Resolves an Organization id into the canonical option entry consumed by
  # the autocomplete FormKit field — same shape `FieldOrganization` builds
  # client-side. Reused by `map_value` for top-level form fields and by the
  # advanced search filter prefill path.
  def self.resolve_option(id, current_user:)
    organization = Pundit.policy_scope!(current_user, Organization).find_by(id: id)
    return if !organization

    {
      value:        organization.id,
      label:        organization.name,
      organization: FormUpdater::Graphql::Serializers::Organization.serialize(organization, current_user:),
    }
  end

  def can_handle_field?(field:, field_attribute:)
    field_attribute&.data_option&.[]('relation') == 'Organization'
  end

  def map_value(field:, config:)
    option = self.class.resolve_option(config['value'], current_user: context[:current_user])
    return if !option

    result[field][:value] = option[:value]
    result[field][:options] = [option]
  end
end
