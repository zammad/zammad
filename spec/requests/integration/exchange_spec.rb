# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Exchange integration endpoint', type: :request do
  before { authenticated_as(admin_with_admin_user_permissions) }

  let(:admin_with_admin_user_permissions) do
    create(:user, roles: [role_with_admin_user_permissions])
  end

  let(:role_with_admin_user_permissions) do
    create(:role).tap { |role| role.permission_grant('admin.integration') }
  end

  describe 'EWS folder retrieval' do
    # see https://github.com/zammad/zammad/issues/1802
    context 'when no folders found (#1802)' do
      let(:empty_folder_list) { { folders: {} } }

      it 'responds with an error message' do
        allow(Sequencer).to receive(:process).with(any_args).and_return(empty_folder_list)

        post api_v1_integration_exchange_folders_path,
             params: {}, as: :json

        expect(json_response).to include('result' => 'failed').and include('message')
      end
    end
  end

  describe 'autodiscovery' do
    # see https://github.com/zammad/zammad/issues/2065
    context 'when Autodiscover gem raises Errno::EADDRNOTAVAIL (#2065)' do
      let(:client) { instance_double('Autodiscover::Client') }

      it 'rescues and responds with an empty hash (to proceed to manual configuration)' do
        allow(Autodiscover::Client).to receive(:new).with(any_args).and_return(client)
        allow(client).to receive(:autodiscover).and_raise(Errno::EADDRNOTAVAIL)

        post api_v1_integration_exchange_autodiscover_path,
             params: {}, as: :json

        expect(json_response).to eq('result' => 'ok')
      end
    end
  end
end
