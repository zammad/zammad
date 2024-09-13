# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'FormUpdater::AppliesTaskbarState' do |taskbar_key:, taskbar_callback:, apply_state_group_keys:|
  context 'when applying taskbar state' do

    let(:taskbar)         { create(:taskbar, key: taskbar_key, callback: taskbar_callback, user_id: user.id, state: taskbar_state) }
    let(:taskbar_state)   { { 'title' => 'test' } }
    let(:field_name)      { 'title' }
    let(:field_result)    { { value: 'test' } }
    let(:additional_data) { { 'taskbarId' => Gql::ZammadSchema.id_from_object(taskbar), 'applyTaskbarState' => true } }
    let(:meta)            { { additional_data: } }

    shared_examples 'skips the field' do
      it 'skips the field' do
        expect(resolved_result.resolve[:fields][field_name]).not_to have_key(:value)
      end
    end

    shared_examples 'applies the form value of the field' do
      it 'applies the form value of the field' do
        expect(resolved_result.resolve[:fields][field_name]).to include(field_result)
      end
    end

    context 'without an associated taskbar' do
      let(:additional_data) { {} }

      include_examples 'skips the field'
    end

    context 'with an associated taskbar' do

      context 'with simple field' do
        include_examples 'applies the form value of the field'
      end

      context 'with formSenderType field' do
        let(:taskbar_state) { { 'formSenderType' => 'phone-in' } }
        let(:field_name)    { 'articleSenderType' }
        let(:field_result)  { { value: 'phone-in' } }

        include_examples 'applies the form value of the field'
      end

      context 'with cc field' do
        let(:taskbar_state) { { 'cc' => 'recipient1@example.org, recipient2@example.org' } }
        let(:field_name)    { 'cc' }
        let(:field_result)  { { value: %w[recipient1@example.org recipient2@example.org] } }

        include_examples 'applies the form value of the field'
      end

      context 'with tags field' do
        let(:taskbar_state) { { 'tags' => 'tag1, tag2, tag3' } }
        let(:field_name)    { 'tags' }
        let(:field_result)  { { value: %w[tag1 tag2 tag3] } }

        include_examples 'applies the form value of the field'
      end

      context 'with blank field' do
        let(:taskbar_state) { { 'title' => '' } }
        let(:field_name)    { 'title' }
        let(:field_result)  { { value: '' } }

        include_examples 'applies the form value of the field'
      end

      context 'with group which should be flatten' do
        let(:taskbar_state) do
          flat_state = { 'priority_id' => 1 }

          if apply_state_group_keys.present?
            return { apply_state_group_keys.first => flat_state }
          end

          flat_state
        end
        let(:field_name)    { 'priority_id' }
        let(:field_result)  { { value: 1 } }

        include_examples 'applies the form value of the field'
      end

      context 'with formId + attachments field' do
        let(:form_id) { SecureRandom.uuid }

        let(:taskbar_state) do
          if taskbar_key.start_with?('TicketCreate')
            {
              'form_id' => form_id,
            }
          elsif taskbar_key.start_with?('TicketZoom')
            {
              'ticket'  => {},
              'article' => {
                'form_id' => form_id,
              },
            }
          end
        end

        let(:field_name) { 'attachments' }
        let(:field_result) do
          {
            value: [
              {
                id:   Gql::ZammadSchema.id_from_object(Store.last),
                name: 'some_file.pdf',
                size: '12',
                type: 'application/pdf',
              }
            ]
          }
        end

        before do
          create(:store,
                 object:      'UploadCache',
                 o_id:        form_id,
                 data:        'dGVzdCAxMjM=',
                 filename:    'some_file.pdf',
                 preferences: {
                   'Content-Type': 'application/pdf',
                   'Content-ID':   'application/pdf@01CAB192.K8H512Y9',
                 })
        end

        include_examples 'applies the form value of the field'
      end
    end
  end
end
