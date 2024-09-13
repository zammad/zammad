# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'FormUpdater::StoresTaskbarState' do |taskbar_key:, taskbar_callback:, store_state_collect_group_key:, store_state_group_keys:|
  context 'when storing taskbar state' do
    let(:data)            { { 'title' => 'test' } }
    let(:field_name)      { 'title' }
    let(:field_result)    { 'test' }
    let(:taskbar)         { create(:taskbar, key: taskbar_key, callback: taskbar_callback, user_id: user.id) }
    let(:additional_data) { { 'taskbarId' => Gql::ZammadSchema.id_from_object(taskbar) } }
    let(:meta)            { { additional_data: } }

    shared_examples 'omits the field' do
      it 'omits the field' do
        expect { resolved_result.resolve }.to not_change {
                                                state = taskbar.reload.state

                                                field_value = state[field_name]
                                                if (!store_state_group_keys || store_state_group_keys.exclude?(field_name)) && store_state_collect_group_key.present?
                                                  field_value = state.dig(store_state_collect_group_key, field_name)
                                                end

                                                field_value
                                              }
      end
    end

    shared_examples 'stores the form value of the field' do
      it 'stores the form value of the field' do
        expect { resolved_result.resolve }.to change {
                                                state = taskbar.reload.state

                                                field_value = state[field_name]
                                                if (!store_state_group_keys || store_state_group_keys.exclude?(field_name)) && store_state_collect_group_key.present?
                                                  field_value = state.dig(store_state_collect_group_key, field_name)
                                                end

                                                field_value
                                              }.to(field_result)
      end
    end

    shared_examples 'stores all form values of the fields' do
      it 'stores the form values of the fields' do
        resolved_result.resolve

        current_check_state = taskbar.reload.state
        if (!store_state_group_keys || store_state_group_keys.exclude?(field_name)) && store_state_collect_group_key.present?
          current_check_state = current_check_state[store_state_collect_group_key]
        end

        expect(current_check_state).to include(field_result)
      end
    end

    context 'without an associated taskbar' do
      let(:additional_data) { {} }

      include_examples 'omits the field'
    end

    context 'with an associated taskbar' do

      context 'with simple field' do
        include_examples 'stores the form value of the field'
      end

      context 'with articleSenderType field' do
        let(:data)         { { 'articleSenderType' => 'phone-in' } }
        let(:field_name)   { 'formSenderType' }
        let(:field_result) { 'phone-in' }

        include_examples 'stores the form value of the field'
      end

      context 'with cc field' do
        let(:data)         { { 'cc' => %w[recipient1@example.org recipient2@example.org] } }
        let(:field_name)   { 'cc' }
        let(:field_result) { 'recipient1@example.org, recipient2@example.org' }

        include_examples 'stores the form value of the field'

        context 'with cc field inside articles' do
          let(:data)         { { 'article' => { 'cc' => %w[recipient1@example.org recipient2@example.org] } } }
          let(:field_name)   { 'article' }
          let(:field_result) do
            if store_state_group_keys.present? && store_state_group_keys.include?('article')
              { 'cc' => 'recipient1@example.org, recipient2@example.org' }
            else
              { 'cc' => %w[recipient1@example.org recipient2@example.org] }
            end
          end

          include_examples 'stores the form value of the field'
        end
      end

      context 'with tags field' do
        let(:data)         { { 'tags' => %w[tag1 tag2 tag3] } }
        let(:field_name)   { 'tags' }
        let(:field_result) { 'tag1, tag2, tag3' }

        include_examples 'stores the form value of the field'
      end

      context 'with attachments field' do
        let(:data)       { { 'attachments' => [{ 'id' => 999, 'name' => 'lipsum.pdf', 'size' => '113746', 'type' => 'application/pdf' }] } }
        let(:field_name) { 'attachments' }

        include_examples 'omits the field'
      end

      context 'with ticket_duplicate_detection field' do
        let(:data)       { { 'ticket_duplicate_detection' => { 'count' => 0, 'items' => [] } } }
        let(:field_name) { 'ticket_duplicate_detection' }

        include_examples 'omits the field'
      end

      context 'with blank field' do
        let(:data)         { { 'title' => '' } }
        let(:field_name)   { 'title' }
        let(:field_result) { '' }

        include_examples 'stores the form value of the field'
      end

      context 'with multiple fields' do
        let(:data)         { { 'state_id' => 2, 'priority_id' => 3 } }
        let(:field_result) { { 'state_id' => 2, 'priority_id' => 3 } }

        include_examples 'stores all form values of the fields'
      end

      context 'with used group_keys' do
        let(:data)         { { 'article' => { 'body' => 'Example Text', 'articleSenderType' => 'phone-in' } } }
        let(:field_name)   { 'article' }
        let(:field_result) do
          if store_state_group_keys.present? && store_state_group_keys.include?('article')
            { 'body' => 'Example Text', 'formSenderType' => 'phone-in' }
          else
            { 'body' => 'Example Text', 'articleSenderType' => 'phone-in' }
          end
        end

        include_examples 'stores the form value of the field'
      end
    end
  end
end
