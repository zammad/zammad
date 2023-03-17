# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

RSpec::Matchers.define :permit_fields do |expected|
  match { expected.all? { |f| actual.field_authorized?(f) } }
  description { 'checks if FieldScope permits expected fields' }
  failure_message { "did not grant field authorization for #{expected.reject { |f| actual.field_authorized?(f) }}" }
end

RSpec::Matchers.define :forbid_fields do |expected|
  match { expected.all? { |f| !actual.field_authorized?(f) } }
  description { 'checks if FieldScope forbids expected fields' }
  failure_message { "incorrectly grants field authorization for #{expected.select { |f| actual.field_authorized?(f) }}" }
end
