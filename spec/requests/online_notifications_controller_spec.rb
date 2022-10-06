# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe OnlineNotification, type: :request do

  let(:admin)   { create(:admin, groups: Group.all) }
  let(:agent)   { create(:agent, groups: Group.all) }
  let(:user_id) { user.id }

  let(:type_lookup_id) { TypeLookup.by_name('create') }
  let(:object_lookup_id) { ObjectLookup.by_name('User') }

  describe 'request handling' do

    shared_examples 'for successful request' do
      it 'has a good response' do
        get path, params: {}, as: :json

        expect(response).to have_http_status(:ok)
      end
    end

    shared_examples 'for array response' do
      it 'has an array response' do
        get path, params: {}, as: :json

        expect(json_response).to be_a(Array)
      end
    end

    shared_examples 'for hash response' do
      it 'has hash response' do
        get path, params: {}, as: :json

        expect(json_response).to be_a(Hash)
      end
    end

    shared_examples 'for notification id in array' do
      it 'has a notification id' do
        get path, params: {}, as: :json

        expect(json_response[0]['id']).to be online_notification.id
      end
    end

    shared_examples 'for notification id in hash' do
      it 'has a notification id' do
        get path, params: {}, as: :json

        expect(json_response['id']).to be online_notification.id
      end
    end

    shared_examples 'for user id in array' do
      it 'has a user id' do
        get path, params: {}, as: :json

        expect(json_response[0]['user_id']).to eq(user_id)
      end
    end

    shared_examples 'for user id in hash' do
      it 'has a user id' do
        get path, params: {}, as: :json

        expect(json_response['user_id']).to eq(user_id)
      end
    end

    shared_examples 'for object lookup id in array' do
      it 'has a object lookup id' do
        get path, params: {}, as: :json

        expect(json_response[0]['object_lookup_id']).to eq(object_lookup_id)
      end
    end

    shared_examples 'for object lookup id in hash' do
      it 'has a object lookup' do
        get path, params: {}, as: :json

        expect(json_response['object_lookup_id']).to eq(object_lookup_id)
      end
    end

    shared_examples 'for type lookup id in array' do
      it 'has a type lookup id' do
        get path, params: {}, as: :json

        expect(json_response[0]['type_lookup_id']).to eq(type_lookup_id)
      end
    end

    shared_examples 'for type lookup id in hash' do
      it 'has a type lookup' do
        get path, params: {}, as: :json

        expect(json_response['type_lookup_id']).to eq(type_lookup_id)
      end
    end

    shared_examples 'for response with assests' do
      it 'has an assests attribute' do
        get path, params: {}, as: :json

        expect(json_response['assets']).to be_a(Hash)
      end
    end

    shared_examples 'getting all associated online notifications' do

      before { online_notification && authenticated_as(user) }

      context 'when online notifications is requested' do
        let(:path) { '/api/v1/online_notifications' }

        include_examples 'for successful request'
        include_examples 'for array response'
        include_examples 'for notification id in array'
        include_examples 'for user id in array'
        include_examples 'for object lookup id in array'
        include_examples 'for type lookup id in array'
      end

      context 'when online notifications is requested with full params' do
        let(:path) { '/api/v1/online_notifications?full=true' }

        it 'has a record_ids attribute' do
          get path, params: {}, as: :json

          expect(json_response['record_ids'])
            .to be_a(Array)
            .and include(online_notification.id)
        end

        include_examples 'for successful request'
        include_examples 'for hash response'
        include_examples 'for response with assests'
      end

      context 'when online notifications is requested with expand params' do
        let(:path) { '/api/v1/online_notifications?expand=true' }

        it 'has a type attribute' do
          get path, params: {}, as: :json

          expect(json_response[0]['type']).to eq('create')
        end

        it 'has a object attribute' do
          get path, params: {}, as: :json

          expect(json_response[0]['object']).to eq('User')
        end

        include_examples 'for successful request'
        include_examples 'for array response'
        include_examples 'for notification id in array'
        include_examples 'for user id in array'
        include_examples 'for object lookup id in array'
        include_examples 'for type lookup id in array'
      end
    end

    shared_examples 'getting specific associated online notification' do
      before { authenticated_as(user) }

      context 'when specific online notifications is requested' do
        let(:path) { "/api/v1/online_notifications/#{online_notification.id}" }

        include_examples 'for successful request'
        include_examples 'for hash response'
        include_examples 'for notification id in hash'
        include_examples 'for user id in hash'
        include_examples 'for object lookup id in hash'
        include_examples 'for type lookup id in hash'
      end

      context 'when specific online notifications is requested with full params' do
        let(:path) { "/api/v1/online_notifications/#{online_notification.id}?full=true" }

        it 'has a notification id' do
          get path, params: {}, as: :json

          expect(json_response['id']).to be online_notification.id
        end

        include_examples 'for successful request'
        include_examples 'for hash response'
        include_examples 'for response with assests'
      end

      context 'when specific online notifications is requested with expand params' do
        let(:path) { "/api/v1/online_notifications/#{online_notification.id}?expand=true" }

        it 'has a type attribute' do
          get path, params: {}, as: :json

          expect(json_response['type']).to eq('create')
        end

        it 'has a object attribute' do
          get path, params: {}, as: :json

          expect(json_response['object']).to eq('User')
        end

        include_examples 'for successful request'
        include_examples 'for hash response'
        include_examples 'for notification id in hash'
        include_examples 'for user id in hash'
        include_examples 'for object lookup id in hash'
        include_examples 'for type lookup id in hash'
      end

    end

    shared_examples 'getting a different online notification' do
      before { authenticated_as(user) }

      context 'when a different notification is request' do
        let(:path) { "/api/v1/online_notifications/#{different_online_notification.id}" }

        it 'has a forbidden response' do
          get path, params: {}, as: :json

          expect(response).to have_http_status(:forbidden)
        end

        it 'has authorized error message' do
          get path, params: {}, as: :json

          expect(json_response['error']).to eq('Not authorized')
        end

        include_examples 'for hash response'
      end
    end

    context 'with authenticated admin' do
      let(:user) { create(:admin, groups: Group.all) }

      let(:online_notification) do
        create(:online_notification, o_id: admin.id, user_id: user_id, type_lookup_id: type_lookup_id, object_lookup_id: object_lookup_id)
      end

      let(:different_online_notification) do
        create(:online_notification, o_id: admin.id, user_id: agent.id, type_lookup_id: type_lookup_id, object_lookup_id: object_lookup_id)
      end

      it_behaves_like 'getting all associated online notifications'

      it_behaves_like 'getting specific associated online notification'

      it_behaves_like 'getting a different online notification'
    end

    context 'with authenticated agent' do
      let(:user) { create(:agent, groups: Group.all) }

      let(:online_notification) do
        create(:online_notification, o_id: admin.id, user_id: user_id, type_lookup_id: type_lookup_id, object_lookup_id: object_lookup_id)
      end

      let(:different_online_notification) do
        create(:online_notification, o_id: admin.id, user_id: admin.id, type_lookup_id: type_lookup_id, object_lookup_id: object_lookup_id)
      end

      it_behaves_like 'getting all associated online notifications'

      it_behaves_like 'getting specific associated online notification'

      it_behaves_like 'getting a different online notification'
    end

    context 'with authenticated customer' do
      let(:user) { create(:customer) }

      let(:online_notification) do
        create(:online_notification, o_id: user_id, user_id: user_id, type_lookup_id: type_lookup_id, object_lookup_id: object_lookup_id)
      end

      let(:different_online_notification) do
        create(:online_notification, o_id: admin.id, user_id: agent.id, type_lookup_id: type_lookup_id, object_lookup_id: object_lookup_id)
      end

      it_behaves_like 'getting all associated online notifications'

      it_behaves_like 'getting specific associated online notification'

      it_behaves_like 'getting a different online notification'
    end
  end
end
