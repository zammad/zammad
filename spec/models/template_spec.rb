# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'models/concerns/has_audit_logs_examples'

RSpec.describe Template, type: :model do
  it_behaves_like 'HasAuditLogs', update_attribute: 'name', update_value: 'Some updated name'
  describe 'validation' do
    it 'uses Validations::VerifyPerformRulesValidator' do
      expect(described_class).to have_validator(Validations::VerifyPerformRulesValidator).on(:options)
    end

    it 'is valid without a tag option' do
      expect(build(:template, :dummy_data)).to be_valid
    end

    it 'is valid with a non-empty tag option' do
      expect(build(:template, :dummy_data, tags: %w[foo bar])).to be_valid
    end

    it 'rejects a tag option without a tag' do
      template = build(:template, :dummy_data)
      template.options['ticket.tags'] = { 'value' => '' }
      expect(template).not_to be_valid
    end
  end
end
