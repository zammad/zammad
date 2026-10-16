# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Issue4943SsoRoleMapping, type: :db_migration do
  %w[saml openid_connect].each do |provider|
    context "with #{provider}" do
      let(:setting) { Setting.find_by(name: "auth_#{provider}_credentials") }

      before do
        setting.options[:form].reject! { |field| field[:name].start_with?('role_mapping::') }
        setting.preferences[:validations] = Array.wrap(setting.preferences[:validations]) - ['Setting::Validation::AuthRoleMapping']
        setting.save!
      end

      it 'adds the role mapping to the credentials form', :aggregate_failures do
        migrate

        expect(setting.reload.options[:form].pluck(:name).last(3)).to eq(%w[role_mapping::attribute role_mapping::map role_mapping::unmatched])
        expect(setting.preferences[:validations]).to include('Setting::Validation::AuthRoleMapping')
      end

      it 'can run twice' do
        migrate

        expect { migrate }.not_to change { setting.reload.options }
      end
    end
  end
end
