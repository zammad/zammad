# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'FormUpdater::PreparesTicketSignature' do
  context 'when preparing ticket signature' do
    let(:object_name)           { 'ticket' }
    let(:field_name)            { 'body' }
    let(:dirty_fields)          { [] }

    let(:field_result) do
      {
        signature: {
          internalId:   signature.id,
          renderedBody: signature.body,
        },
      }
    end

    let(:signature) { create(:signature, body: 'test') }
    let(:group)     { create(:group, name: 'Example 1', signature:) }

    shared_examples 'resetting the signature prop for the field' do
      it 'resets the signature prop for the field' do
        expect(resolved_result.resolve[:fields][field_name][:signature]).to be_nil
      end
    end

    shared_examples 'skipping the signature prop for the field' do
      it 'skips the signature prop for the field' do
        expect(resolved_result.resolve[:fields]).not_to include(field_name => hash_including(:signature))
      end
    end

    shared_examples 'setting the signature prop for the field' do
      it 'sets the signature prop for the field' do
        expect(resolved_result.resolve[:fields][field_name]).to include(field_result)
      end
    end

    context 'when loading initially' do
      context 'without a group present' do
        let(:data) { {} }

        it_behaves_like 'resetting the signature prop for the field'
      end

      context 'with a group present' do
        let(:data) { { 'group_id' => group.id } }

        it_behaves_like 'setting the signature prop for the field'
      end
    end

    context 'when changing the group' do
      let(:meta) { { changed_field: { name: 'group_id' } } }

      context 'without a group present' do
        let(:data) { {} }

        it_behaves_like 'resetting the signature prop for the field'
      end

      context 'with a group present' do
        let(:data) { { 'group_id' => group.id } }

        it_behaves_like 'setting the signature prop for the field'
      end
    end

    context 'when changing the article type' do
      let(:meta) { { changed_field: { name: 'articleSenderType' } } }

      context 'without a group present' do
        let(:data) { {} }

        it_behaves_like 'resetting the signature prop for the field'
      end

      context 'with a group present' do
        let(:data) { { 'group_id' => group.id } }

        it_behaves_like 'setting the signature prop for the field'
      end
    end

    context 'when changing the priority' do
      let(:meta) { { changed_field: { name: 'priority_id' } } }

      it_behaves_like 'skipping the signature prop for the field'
    end
  end
end
