# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ObjectManager::Element::Backend do
  subject(:element) { described_class.new(user: user, attribute: attribute, record: nil) }

  let(:user) { create(:agent) }
  let(:attribute) do
    build(:object_manager_attribute_autocompletion_ajax_external_data_source).tap do |attribute|
      attribute.data_option.merge!(
        'http_basic_auth_username' => 'user',
        'http_basic_auth_password' => 'secret',
        'bearer_token_auth'        => 'token',
        'verify_ssl'               => false,
      )
    end
  end

  describe '#data' do
    it 'does not expose the external data source credentials', :aggregate_failures do
      expect(element.data.keys)
        .not_to include(:search_url, :search_result_list_key, :search_result_value_key, :search_result_label_key, :http_basic_auth_username, :http_basic_auth_password, :bearer_token_auth, :verify_ssl)

      expect(element.data).to include(null: true)
    end
  end
end
