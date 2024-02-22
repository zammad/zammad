# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

RSpec::Matchers.define :permit_fields do |expected|
  description { 'checks if FieldScope permits expected fields' }
  failure_message { "did not grant field authorization for #{expected.reject { |f| actual.field_authorized?(f) }}" }

  match do
    # any field is permitted if value is true (boolean)
    next true if actual === true # rubocop:disable Style/CaseEquality

    expected.all? { |f| actual.field_authorized?(f) }
  end
end

RSpec::Matchers.define :forbid_fields do |expected|
  description { 'checks if FieldScope forbids expected fields' }
  failure_message { "incorrectly grants field authorization for #{expected.select { |f| actual.field_authorized?(f) }}" }

  match do
    # any field is forbidden if value is falsey
    next if !actual

    expected.all? { |f| !actual.field_authorized?(f) }
  end
end
