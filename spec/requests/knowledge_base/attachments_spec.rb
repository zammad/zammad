# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'KnowledgeBase attachments', type: :request, authenticated_as: :current_user do
  include_context 'basic Knowledge Base'

  let(:store_file_content) do
    Rails.root.join('spec/fixtures/files/upload/hello_world.txt').read
  end
  let(:store_file_name) { 'hello_world.txt' }

  let(:attachment) do
    create(:store,
           object:        object.class.to_s,
           o_id:          object.id,
           data:          store_file_content,
           filename:      store_file_name,
           preferences:   {},
           created_by_id: 1,)
  end

  let(:endpoint)     { "/api/v1/attachments/#{attachment.id}" }
  let(:current_user) { create(user_identifier) if defined?(user_identifier) }

  describe 'visible when attached to' do
    shared_examples 'a visible resource' do
      it 'and returns correct status code' do
        get endpoint
        expect(response).to have_http_status(:ok)
      end
    end

    shared_examples 'a non-existent resource' do
      it 'and returns correct status code' do
        get endpoint
        expect(response).to have_http_status(:not_found)
      end
    end

    shared_examples 'previewing a calendar file' do
      context 'with calendar preview' do
        let(:store_file_content) do
          Rails.root.join('spec/fixtures/files/calendar/basic.ics').read
        end
        let(:store_file_name) { 'basic.ics' }

        let(:expected_event) do
          {
            'title'       => 'Test Summary',
            'location'    => 'https://us.zoom.us/j/example?pwd=test',
            'start_date'  => '2021-07-27T10:30:00.000+02:00',
            'end_date'    => '2021-07-27T12:00:00.000+02:00',
            'attendees'   => ['M.bob@example.com', 'J.doe@example.com'],
            'organizer'   => 'f.sample@example.com',
            'description' => 'Test description'
          }
        end

        before { get "#{endpoint}?preview=1&type=calendar" }

        it 'responds with ok status' do
          expect(response).to have_http_status(:ok)
        end

        it 'returns a kind of hash' do
          expect(json_response).to be_a(Hash)
        end

        it 'responds with the correct file name' do
          expect(json_response['filename']).to eq store_file_name
        end

        it 'renders a parsed calender data' do
          expect(json_response['events'].first).to include(expected_event)
        end
      end
    end

    describe 'draft answer' do
      let(:object) { draft_answer }

      describe 'as agent' do
        let(:user_identifier) { :agent }

        it_behaves_like 'a non-existent resource'
      end

      context 'as admin' do
        let(:user_identifier) { :admin }

        it_behaves_like 'a visible resource'
        it_behaves_like 'previewing a calendar file'
      end

      context 'as customer' do
        let(:user_identifier) { :customer }

        it_behaves_like 'a non-existent resource'
      end

      context 'as guest' do
        it_behaves_like 'a non-existent resource'
      end
    end

    describe 'internal answer' do
      let(:object) { internal_answer }

      describe 'as agent' do
        let(:user_identifier) { :agent }

        it_behaves_like 'a visible resource'
        it_behaves_like 'previewing a calendar file'
      end

      context 'as admin' do
        let(:user_identifier) { :admin }

        it_behaves_like 'a visible resource'
        it_behaves_like 'previewing a calendar file'
      end

      context 'as customer' do
        let(:user_identifier) { :customer }

        it_behaves_like 'a non-existent resource'
      end

      context 'as guest' do
        it_behaves_like 'a non-existent resource'
      end
    end

    describe 'published answer' do
      let(:object) { published_answer }

      describe 'as agent' do
        let(:user_identifier) { :agent }

        it_behaves_like 'a visible resource'
        it_behaves_like 'previewing a calendar file'
      end

      context 'as admin' do
        let(:user_identifier) { :admin }

        it_behaves_like 'a visible resource'
        it_behaves_like 'previewing a calendar file'
      end

      context 'as customer' do
        let(:user_identifier) { :customer }

        it_behaves_like 'a visible resource'
        it_behaves_like 'previewing a calendar file'
      end

      context 'as guest' do
        it_behaves_like 'a visible resource'
        it_behaves_like 'previewing a calendar file'
      end
    end

    describe 'archived answer' do
      let(:object) { archived_answer }

      describe 'as agent' do
        let(:user_identifier) { :agent }

        it_behaves_like 'a non-existent resource'
      end

      context 'as admin' do
        let(:user_identifier) { :admin }

        it_behaves_like 'a visible resource'
        it_behaves_like 'previewing a calendar file'
      end

      context 'as customer' do
        let(:user_identifier) { :customer }

        it_behaves_like 'a non-existent resource'
      end

      context 'as guest' do
        it_behaves_like 'a non-existent resource'
      end
    end
  end

  describe 'deletable when attached to' do
    shared_examples 'a deletable resource' do
      it { expect { delete endpoint }.to change { Store.exists? attachment.id }.from(true).to(false) }
    end

    shared_examples 'a non-deletable resource' do
      it { expect { delete endpoint }.not_to change { Store.exists? attachment.id }.from(true) }
    end

    describe 'draft answer' do
      let(:object) { draft_answer }

      describe 'as agent' do
        let(:user_identifier) { :agent }

        it_behaves_like 'a non-deletable resource'
      end

      context 'as admin' do
        let(:user_identifier) { :admin }

        it_behaves_like 'a deletable resource'
      end

      context 'as customer' do
        let(:user_identifier) { :customer }

        it_behaves_like 'a non-deletable resource'
      end

      context 'as guest' do
        it_behaves_like 'a non-deletable resource'
      end
    end

    describe 'internal answer' do
      let(:object) { internal_answer }

      describe 'as agent' do
        let(:user_identifier) { :agent }

        it_behaves_like 'a non-deletable resource'
      end

      context 'as admin' do
        let(:user_identifier) { :admin }

        it_behaves_like 'a deletable resource'
      end

      context 'as customer' do
        let(:user_identifier) { :customer }

        it_behaves_like 'a non-deletable resource'
      end

      context 'as guest' do
        it_behaves_like 'a non-deletable resource'
      end
    end

    describe 'published answer' do
      let(:object) { published_answer }

      describe 'as agent' do
        let(:user_identifier) { :agent }

        it_behaves_like 'a non-deletable resource'
      end

      context 'as admin' do
        let(:user_identifier) { :admin }

        it_behaves_like 'a deletable resource'
      end

      context 'as customer' do
        let(:user_identifier) { :customer }

        it_behaves_like 'a non-deletable resource'
      end

      context 'as guest' do
        it_behaves_like 'a non-deletable resource'
      end
    end

    describe 'archived answer' do
      let(:object) { archived_answer }

      describe 'as agent' do
        let(:user_identifier) { :agent }

        it_behaves_like 'a non-deletable resource'
      end

      context 'as admin' do
        let(:user_identifier) { :admin }

        it_behaves_like 'a deletable resource'
      end

      context 'as customer' do
        let(:user_identifier) { :customer }

        it_behaves_like 'a non-deletable resource'
      end

      context 'as guest' do
        it_behaves_like 'a non-deletable resource'
      end
    end
  end
end
