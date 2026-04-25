# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Ticket::SharedDraft::Start::Update do
  subject(:service_result) { described_class.with_current_user(user).execute(shared_draft, form_id, content:, group:) }

  let(:group)        { create(:group) }
  let(:content)      { { content: Faker::Lorem.unique.sentence } }
  let(:form_id)      { 123 }
  let(:shared_draft) { create(:ticket_shared_draft_start, group:, name: draft_name) }
  let(:draft_name)   { 'initial draft name' }

  let(:user) do
    create(:agent)
      .tap { |elem| elem.user_groups.create!(group:, access: :create) }
  end

  context 'when user has access to the draft group' do
    it 'returns new object' do
      service_result

      expect(shared_draft.reload).to have_attributes(name: draft_name, content:, group:)
    end

    # name can be changed via REST api, but GraphQL mutation does not support it
    context 'when name is given' do
      subject(:service_result) { described_class.with_current_user(user).execute(shared_draft, form_id, content:, group:, name: 'new name') }

      it 'changes name if given' do
        service_result

        expect(shared_draft.reload).to have_attributes(name: 'new name')
      end
    end

    it 'copies attachments from the given form' do
      create(:store, o_id: form_id)

      service_result

      expect(Store.list(object: shared_draft.class.name, o_id: shared_draft.id))
        .to contain_exactly(have_attributes(filename: 'test.txt'))
    end
  end

  context 'when user has insufficient access to the target draft group' do
    subject(:service_result) { described_class.with_current_user(user).execute(shared_draft, form_id, content:, group: new_group) }

    let(:new_group) { create(:group) }

    before do
      allow(user).to receive(:group_access?).with(new_group.id, :create).and_return(false)
    end

    it 'raises an error' do
      expect { service_result }
        .to raise_error(Pundit::NotAuthorizedError)
    end
  end

end
