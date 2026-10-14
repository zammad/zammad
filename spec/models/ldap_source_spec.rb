# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/concerns/has_audit_logs_examples'

RSpec.describe LdapSource, type: :model do
  it_behaves_like 'HasAuditLogs', update_attribute: 'name', update_value: 'Some updated name'

  describe 'Validations' do
    subject(:ldap_source) { create(:ldap_source) }

    it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
  end
end
