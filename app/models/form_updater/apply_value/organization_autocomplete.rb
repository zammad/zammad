# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class FormUpdater::ApplyValue::OrganizationAutocomplete < FormUpdater::ApplyValue::Base

  # Resolves an Organization id into the canonical option entry consumed by
  # the autocomplete FormKit field — same shape `FieldOrganization` builds
  # client-side. Reused by `map_value` for top-level form fields and by the
  # advanced search filter prefill path.
  #
  # TODO: visibility is not enforced here yet — the lookup is a plain find_by.
  # The taskbar / template-restore paths already worked this way; the filter
  # prefill inherits that and will be tightened together with the apply-value
  # path in a follow-up.
  def self.resolve_option(id)
    organization = Organization.find_by(id: id)
    return if !organization

    {
      value:        organization.id,
      label:        organization.name,
      organization: FormUpdater::Graphql::Serializers::Organization.serialize(organization),
    }
  end

  def can_handle_field?(field:, field_attribute:)
    field_attribute&.data_option&.[]('relation') == 'Organization'
  end

  def map_value(field:, config:)
    option = self.class.resolve_option(config['value'])
    return if !option

    result[field][:value] = option[:value]
    result[field][:options] = [option]
  end
end
