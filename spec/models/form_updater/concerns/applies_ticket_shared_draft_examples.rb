# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'FormUpdater::AppliesTicketSharedDraft' do |draft_type: 'start'|
  context 'when applying a ticket shared draft' do

    let(:object_name)           { 'ticket' }
    let(:field_name)            { 'title' }
    let(:field_draft_value)     { 'test' }
    let(:field_result)          { { value: 'test' } }
    let(:dirty_fields)          { [] }
    let(:additional_data)       { { 'sharedDraftId' => Gql::ZammadSchema.id_from_object(draft), 'draftType' => draft_type } }
    let(:meta)                  { { additional_data:, dirty_fields: } }
    let(:draft) do
      if draft_type == 'start'
        create(:ticket_shared_draft_start, group: user.groups.first, content: { field_name => field_draft_value })
      elsif draft_type == 'detail-view'
        create(:ticket_shared_draft_zoom, ticket: create(:ticket, group: group), new_article: { body: '4711' }, ticket_attributes: { field_name => field_draft_value })
      end
    end

    shared_examples 'skips the field' do
      it 'skips the field' do
        expect(resolved_result.resolve[:fields][field_name]).not_to have_key(:value)
      end
    end

    shared_examples 'sets the draft value for the field' do
      it 'sets the draft value for the field' do
        expect(resolved_result.resolve[:fields][field_name]).to include(field_result)
      end
    end

    context 'without a draft to be applied' do
      let(:additional_data) { {} }

      include_examples 'skips the field'
    end

    context 'with a draft to be applied' do

      context 'with implicit draft internal identifier' do
        let(:field_name)   { 'shared_draft_id' }
        let(:field_result) { { value: draft.id } }

        include_examples 'sets the draft value for the field'
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
        let(:search_user)           { create(:user) }
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

        context 'with unknown email' do
          let(:search_user) { 'dummy@non-existing.com' }
          let(:field_draft_value) { search_user }
          let(:field_result) do
            {
              value:   [search_user],
              options: [{ value: search_user, label: search_user }]
            }
          end

          include_examples 'sets the draft value for the field'
        end

        context 'with multiple recipients' do
          let(:recipient_user)    { create(:user) }
          let(:recipient_email)   { 'dummy@non-existing.com' }
          let(:field_draft_value) { "#{recipient_user.email}, #{recipient_email}" }
          let(:field_result) do
            {
              value:   [recipient_user.email, recipient_email],
              options: [
                { value: recipient_user.email, label: recipient_user.email, heading: recipient_user.fullname },
                { value: recipient_email, label: recipient_email },
              ],
            }
          end

          include_examples 'sets the draft value for the field'
        end
      end

      context 'with attachments' do
        let(:object_name)           { 'article' }
        let(:field_name)            { 'attachments' }
        let(:field_draft_value)     { [] }
        let(:original_attachment)   { create(:store, object: draft.class.name, o_id: draft.id) }
        let(:form_id)               { SecureRandom.uuid }
        let(:meta)                  { { additional_data:, dirty_fields:, form_id: } }

        let(:field_result) do
          {
            value: [
              {
                id:   cloned_attachment.id,
                name: cloned_attachment.filename,
                size: cloned_attachment.size,
                type: cloned_attachment.preferences['Content-Type'],
              }
            ]
          }
        end

        let(:cloned_attachment) { Store.list(object: 'UploadCache', o_id: form_id).first }

        before { original_attachment }

        include_examples 'sets the draft value for the field'
      end

      context 'with organization autocomplete fields' do
        let(:search_organization)   { create(:organization) }
        let(:object_attribute)      { create(:object_manager_attribute_organization_autocompletion) }
        let(:field_name)            { object_attribute.name }
        let(:field_draft_value)     { search_organization.id.to_s }
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
        let(:draft) do
          if draft_type == 'start'
            create(:ticket_shared_draft_start, group: user.groups.first, content: { 'group_id' => group.id.to_s, 'owner_id' => user.id.to_s })
          elsif draft_type == 'detail-view'
            create(:ticket_shared_draft_zoom, ticket: create(:ticket, group: group), new_article: { body: '4711' }, ticket_attributes: { 'group_id' => group.id.to_s, 'owner_id' => user.id.to_s })
          end
        end

        it 'sets the draft value for both fields', :aggregate_failures do
          expect(resolved_result.resolve[:fields]['group_id']).to include(value: group.id)
          expect(resolved_result.resolve[:fields]['owner_id']).to include(value: user.id)
        end
      end
    end
  end
end
