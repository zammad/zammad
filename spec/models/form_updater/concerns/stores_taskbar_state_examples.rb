# Copyright (C) 2012-2024 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'FormUpdater::StoresTaskbarState' do |taskbar_key:, taskbar_callback:|
  context 'when storing taskbar state' do

    let(:data)            { { 'title' => 'test' } }
    let(:field_name)      { 'title' }
    let(:field_result)    { 'test' }
    let(:taskbar)         { create(:taskbar, key: taskbar_key, callback: taskbar_callback, user_id: user.id) }
    let(:additional_data) { { 'taskbarId' => Gql::ZammadSchema.id_from_object(taskbar) } }
    let(:meta)            { { additional_data: } }

    shared_examples 'omits the field' do
      it 'omits the field' do
        expect { resolved_result.resolve }.to not_change { taskbar.reload.state[field_name] }
      end
    end

    shared_examples 'stores the form value of the field' do
      it 'stores the form value of the field' do
        expect { resolved_result.resolve }.to change { taskbar.reload.state[field_name] }.to(field_result)
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
    end
  end
end
