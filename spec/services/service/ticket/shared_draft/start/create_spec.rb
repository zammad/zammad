# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Ticket::SharedDraft::Start::Create do
  let(:group)   { create(:group) }
  let(:content) { { content: Faker::Lorem.unique.sentence } }
  let(:name)    { Faker::Lorem.unique.sentence }
  let(:form_id) { 123 }

  let(:service_result) do
    described_class
      .with_current_user(user)
      .execute(form_id, name:, content:, group:)
  end

  context 'when user has access to the draft group' do
    let(:user) do
      create(:agent)
        .tap { |elem| elem.user_groups.create!(group:, access: :create) }
    end

    it 'returns new object' do
      expect(service_result).to have_attributes(name:, content:, group:)
    end

    it 'copies attachments from the given form' do
      create(:store, o_id: form_id, created_by_id: user.id)

      expect(Store.list(object: service_result.class.name, o_id: service_result.id))
        .to contain_exactly(have_attributes(filename: 'test.txt'))
    end

    context 'when has inline attachments' do
      let(:content) { attributes_for(:ticket_shared_draft_start, :with_inline_image)[:content] }

      before do
        UserInfo.with_user_id(user.id) do
          UploadCache.new(form_id).add(
            filename:      'image1.jpeg',
            data:          'fake-image-data',
            preferences:   { 'Content-Disposition' => 'inline' },
            created_by_id: user.id,
          )
        end
      end

      it 'copies inline attachment and keeps it inline' do
        expect(Store.list(object: service_result.class.name, o_id: service_result.id))
          .to contain_exactly(have_attributes(
                                filename:    'image1.jpeg',
                                preferences: include('Content-Disposition' => 'inline')
                              ))
      end
    end
  end

  context 'when user has insufficient access to the draft group' do
    let(:user) { create(:agent) }

    it 'raises an error' do
      expect { service_result }.to raise_error(Pundit::NotAuthorizedError)
    end
  end
end
