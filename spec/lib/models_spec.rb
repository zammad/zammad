# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Models do

  describe '.merge' do

    context 'when ExternalSync references are present' do

      shared_examples 'migrates entries' do |model|

        let(:factory_name) { model.downcase.to_sym }
        let(:source)       { create(factory_name) }
        let(:target)       { create(factory_name) }

        it 'sends ExternalSync.migrate' do
          allow(ExternalSync).to receive(:migrate)
          described_class.merge(model, source.id, target.id)
          expect(ExternalSync).to have_received(:migrate).with(model, source.id, target.id)
        end
      end

      it_behaves_like 'migrates entries', 'User'
    end
  end

  describe '.searchable' do
    it 'lists all needed models' do
      expect(described_class.searchable).to contain_exactly(Ticket, User, Organization, Chat::Session, KnowledgeBase::Answer::Translation)
    end
  end

  describe '.references' do
    # User object is handled slightly differently
    # Due to not having Rails relations for performance reasons
    context 'with User' do
      let(:role)  { create(:role) }
      let(:group1) { create(:group) }
      let(:group2) { create(:group) }
      let(:user1)  { create(:user, roles: [role], groups: [group1, group2]) }
      let(:user2)  do
        create(:user, roles: [role], groups: [group1, group2],
                            updated_by_id: user1.id)
      end
      let(:user3) do
        create(:user, roles: [role], groups: [group1, group2],
                            updated_by_id: user1.id, created_by_id: user1.id)
      end
      let(:organization) { create(:organization, updated_by_id: user1.id) }

      before do
        user1 && user2 && user3 && organization
      end

      it 'returns existing references' do
        references = described_class.references('User', user1.id)

        expect(references)
          .to eq({
                   'History'      => { 'created_by_id' => 1 },
                   'Organization' => { 'updated_by_id' => 1 },
                   'User'         => {
                     'created_by_id' => 1,
                     'updated_by_id' => 2
                   },
                   'UserGroup'    => { 'user_id' => 2 }
                 })
      end

      it 'returns existing references and includes attributes with no references found' do
        references = described_class.references('User', user1.id, true)

        expect(references).to include(
          'History'      => { 'created_by_id' => 1, },
          'Organization' => {
            'created_by_id' => 0,
            'updated_by_id' => 1
          },
          'User'         => {
            'created_by_id' => 1, 'out_of_office_replacement_id' => 0, 'updated_by_id' => 2
          },
          'UserGroup'    => { 'user_id' => 2 },
          'Taskbar'      => { 'user_id'=>0 },
        )
      end
    end

    context 'with an example object' do
      let(:organization) { create(:organization) }
      let(:user)         { create(:user, organization: organization) }

      before { user }

      it 'returns existing references' do
        references = described_class.references('Organization', organization.id, false)

        expect(references).to eq({
                                   'User' => { 'organization_id'=>1 },
                                 })
      end

      it 'returns existing references and includes attributes with no references found' do
        references = described_class.references('Organization', organization.id, true)

        expect(references).to eq({
                                   'Ticket' => { 'organization_id'=>0 },
                                   'User'   => { 'organization_id'=>1 },
                                 })
      end

      it 'raises an error if non existing object is given' do
        expect { described_class.references('Organization', 123_456) }
          .to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe '.references_total' do
    it 'returns total count' do
      allow(described_class)
        .to receive(:references)
        .and_return({
                      'Klass'        => { 'attr_id' => 1 },
                      'AnotherKlass' => { 'attr_id' => 2, 'something_id' => 4 },
                    })

      count = described_class.references_total('User', 123)

      expect(count).to eq(7)
    end
  end
end
