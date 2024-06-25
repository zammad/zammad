# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'FormUpdater::AppliesTicketSharedDraft' do
  context 'when applying a ticket shared draft' do

    let(:object_name)           { 'ticket' }
    let(:field_name)            { 'title' }
    let(:field_draft_value)     { 'test' }
    let(:field_result)          { { value: 'test' } }
    let(:draft)                 { create(:ticket_shared_draft_start, group: user.groups.first, content: { field_name => field_draft_value }) }
    let(:dirty_fields)          { [] }
    let(:additional_data)       { { 'sharedDraftStartId' => Gql::ZammadSchema.id_from_object(draft) } }
    let(:meta)                  { { additional_data:, dirty_fields: } }

    shared_examples 'skips the field' do
      it 'skips the field' do
        expect(resolved_result.resolve[field_name]).not_to have_key(:value)
      end
    end

    shared_examples 'sets the draft value for the field' do
      it 'sets the draft value for the field' do
        expect(resolved_result.resolve[field_name]).to include(field_result)
      end
    end

    context 'without a draft to be applied' do
      let(:additional_data) { {} }

      include_examples 'skips the field'
    end

    context 'with a draft to be applied' do

      context 'when the field is dirty and has a value' do
        let(:data)         { { field_name => 'previous value' } }
        let(:dirty_fields) { [field_name] }

        include_examples 'skips the field'
      end

      context 'when a value is present, but the field is not marked as dirty' do
        let(:data) { { field_name: 'already present' } }

        include_examples 'sets the draft value for the field'
      end

      context 'with simple fields' do
        include_examples 'sets the draft value for the field'
      end

      context 'with tags field' do
        let(:data)                  { { 'tags' => %w[tag2 tag3] } }
        let(:field_name)            { 'tags' }
        let(:field_draft_value)     { 'tag1, tag2' }
        let(:field_result)          { { value: %w[tag1 tag2] } }

        include_examples 'sets the draft value for the field'
      end

      context 'with user autocomplete fields' do
        let(:search_user)           { create(:user, organization: create(:organization)) }
        let(:object_attribute)      { create(:object_manager_attribute_user_autocompletion) }
        let(:field_name)            { object_attribute.name }
        let(:field_draft_value)     { search_user.id }
        let(:field_result) do
          {
            value:   search_user.id,
            options: [{
              value:   search_user.id,
              label:   search_user.fullname,
              heading: search_user.organization.name,
              object:  search_user.attributes
                        .slice('active', 'email', 'firstname', 'fullname', 'image', 'lastname', 'mobile', 'out_of_office', 'out_of_office_end_at', 'out_of_office_start_at', 'phone', 'source', 'vip')
                        .merge({
                                 '__typename' => 'User',
                                 'id'         => Gql::ZammadSchema.id_from_internal_id('User', search_user.id),
                               })

            }]
          }
        end

        include_examples 'sets the draft value for the field'
      end

      context 'with recipient autocomplete fields' do
        let(:search_user)           { create(:user, organization: create(:organization)) }
        let(:object_name)           { 'article' }
        let(:field_name)            { 'cc' }
        let(:field_draft_value)     { search_user.email }
        let(:field_result) do
          {
            value:   [search_user.email],
            options: [{ value: search_user.email, label: search_user.email, heading: search_user.fullname }]
          }
        end

        include_examples 'sets the draft value for the field'

        context 'with unknown user' do
          let(:search_user) { 'dummy@non-existing.com' }
          let(:field_draft_value) { search_user }
          let(:field_result) do
            {
              value:   [search_user],
              options: [{ value: search_user, label: search_user, heading: nil }]
            }
          end

          include_examples 'sets the draft value for the field'
        end
      end

      context 'with organization autocomplete fields' do
        let(:search_organization)   { create(:organization) }
        let(:object_attribute)      { create(:object_manager_attribute_organization_autocompletion) }
        let(:field_name)            { object_attribute.name }
        let(:field_draft_value)     { search_organization.id }
        let(:field_result) do
          {
            value:   search_organization.id,
            options: [{ value: search_organization.id, label: search_organization.name }]
          }
        end

        include_examples 'sets the draft value for the field'
      end

      context 'with date fields' do
        let(:object_attribute)      { create(:object_manager_attribute_date) }
        let(:field_name)            { object_attribute.name }
        let(:field_draft_value)     { '2024-01-01' }
        let(:field_result)          { { value: '2024-01-01' } }

        include_examples 'sets the draft value for the field'
      end

      context 'with datetime fields' do
        let(:object_attribute)      { create(:object_manager_attribute_datetime) }
        let(:field_name)            { object_attribute.name }
        let(:field_draft_value)     { '2024-01-01T00:00:00Z' }
        let(:field_result)          { { value: '2024-01-01T00:00:00Z' } }

        include_examples 'sets the draft value for the field'
      end

      context 'with group and owner fields' do
        let(:group)    { create(:group, name: 'Example 1') }
        let(:user)     { create(:agent, groups: [group]) }
        let(:context)  { { current_user: user } }
        let(:draft)    { create(:ticket_shared_draft_start, group: user.groups.first, content: { 'group_id' => group.id.to_s, 'owner_id' => user.id.to_s }) }

        it 'sets the draft value for both fields', :aggregate_failures do
          expect(resolved_result.resolve['group_id']).to include(value: group.id)
          expect(resolved_result.resolve['owner_id']).to include(value: user.id.to_s)
        end
      end
    end
  end
end
