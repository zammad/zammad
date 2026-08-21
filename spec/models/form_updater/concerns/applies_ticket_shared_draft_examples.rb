# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

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
            options: include(
              include(
                value:   search_user.id,
                label:   search_user.fullname,
                heading: search_user.organization.name,
                object:  include(
                  '__typename'   => 'User',
                  'id'           => Gql::ZammadSchema.id_from_internal_id('User', search_user.id),
                  'organization' => include(
                    '__typename' => 'Organization',
                    'id'         => Gql::ZammadSchema.id_from_internal_id('Organization', search_user.organization.id),
                    'name'       => search_user.organization.name,
                  )
                )
              )
            )
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

      context 'with an inline image referenced via cid' do
        let(:object_name) { 'article' }
        let(:field_name)  { 'body' }
        let(:form_id)     { SecureRandom.uuid }
        let(:meta)        { { additional_data:, dirty_fields:, form_id: } }
        let(:cid)         { 'image1.abcdef12@zammad.example.com' }
        let(:image_data)  { Rails.root.join('test/data/image/1x1.png').binread }
        let(:body)        { %(<img src="cid:#{cid}">) }

        let(:draft) do
          if draft_type == 'start'
            create(:ticket_shared_draft_start, group: user.groups.first, content: { 'body' => body })
          elsif draft_type == 'detail-view'
            create(:ticket_shared_draft_zoom, ticket: create(:ticket, group: group), new_article: { body: body }, ticket_attributes: {})
          end
        end

        # the draft's own inline attachment matching the cid referenced in its body
        let(:inline_attachment) do
          create(:store, object: draft.class.name, o_id: draft.id, filename: 'image1.png', data: image_data,
                          preferences: { 'Content-Type' => 'image/png', 'Content-ID' => cid, 'Content-Disposition' => 'inline' })
        end

        # a pre-existing, unrelated attachment already in the target compose form's
        # UploadCache that collides on filename + size (but not Content-ID) with the
        # draft's inline image -- e.g. left over from a previous apply, or an unrelated
        # image of equal byte size pasted separately into the same compose form.
        let(:colliding_attachment) do
          create(:store, object: 'UploadCache', o_id: form_id, filename: 'image1.png', data: image_data,
                          preferences: { 'Content-Type' => 'image/png' })
        end

        let(:cloned_attachment) do
          Store.list(object: 'UploadCache', o_id: form_id).find { |elem| elem.preferences['Content-ID'] == cid }
        end

        before do
          inline_attachment
          colliding_attachment
        end

        it 'clones the inline image into the target UploadCache and rewrites the cid: reference', :aggregate_failures do
          resolved_body = resolved_result.resolve[:fields][field_name][:value]

          expect(cloned_attachment).to be_present
          expect(resolved_body).to include("/api/v1/attachments/#{cloned_attachment.id}")
          expect(resolved_body).not_to include('cid:')
        end

        # A draft save regenerates the Content-ID of every inline image, so the clone of a
        # previous apply can no longer be recognized as a duplicate. Without cleanup, every
        # save + apply cycle would leave another copy behind in the same UploadCache.
        context 'when the draft was saved and applied before' do
          let(:stale_cid) { 'image1.12345678@zammad.example.com' }

          # leftover of a previous apply: the same image, cloned under the Content-ID the
          # draft carried before it was saved again
          let(:stale_attachment) do
            create(:store, object: 'UploadCache', o_id: form_id, filename: 'image1.png', data: image_data, created_by_id: user.id,
                           preferences: { 'Content-Type' => 'image/png', 'Content-ID' => stale_cid, 'Content-Disposition' => 'inline' })
          end

          # inline image uploaded directly in the editor: no Content-ID, referenced by
          # attachment URL instead of by cid, so it must survive untouched
          let(:editor_attachment) do
            create(:store, object: 'UploadCache', o_id: form_id, filename: 'editor.png', data: image_data, created_by_id: user.id,
                           preferences: { 'Content-Type' => 'image/png', 'Content-Disposition' => 'inline' })
          end

          before do
            stale_attachment
            editor_attachment
          end

          it 'removes the superseded clone and keeps the other inline items', :aggregate_failures do
            resolved_body = resolved_result.resolve[:fields][field_name][:value]

            expect(resolved_body).to include("/api/v1/attachments/#{cloned_attachment.id}")
            expect { stale_attachment.reload }.to raise_error(ActiveRecord::RecordNotFound)
            expect { editor_attachment.reload }.not_to raise_error
            expect { colliding_attachment.reload }.not_to raise_error
          end
        end

        # Some attachments carry their Content-ID under the lowercase 'content_id'
        # preference key instead of 'Content-ID' (e.g. clones of mail-parsed articles, see
        # CanCloneAttachments#attachment_content_id). Cleanup must recognize both.
        context 'when the stale clone stores its Content-ID under the lowercase key' do
          let(:stale_cid) { 'image1.12345678@zammad.example.com' }

          let(:stale_attachment) do
            create(:store, object: 'UploadCache', o_id: form_id, filename: 'image1.png', data: image_data, created_by_id: user.id,
                           preferences: { 'Content-Type' => 'image/png', 'content_id' => stale_cid, 'Content-Disposition' => 'inline' })
          end

          before { stale_attachment }

          it 'removes the superseded clone', :aggregate_failures do
            resolved_body = resolved_result.resolve[:fields][field_name][:value]

            expect(resolved_body).to include("/api/v1/attachments/#{cloned_attachment.id}")
            expect { stale_attachment.reload }.to raise_error(ActiveRecord::RecordNotFound)
          end
        end
      end

      context 'with organization autocomplete fields' do
        let(:search_organization)   { create(:organization) }
        let(:object_attribute)      { create(:object_manager_attribute_organization_autocompletion) }
        let(:field_name)            { object_attribute.name }
        let(:field_draft_value)     { search_organization.id.to_s }
        let(:field_result) do
          {
            value:   search_organization.id,
            options: [{ value: search_organization.id, label: search_organization.name, organization: search_organization.attributes.slice('name', 'shared', 'domain', 'domain_assignment', 'active', 'vip').to_h.transform_keys { |key| key.camelize(:lower) }.merge({ '__typename' => 'Organization', 'id' => Gql::ZammadSchema.id_from_internal_id('Organization', search_organization.id) }) }]
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
