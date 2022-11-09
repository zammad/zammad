# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'
require 'system/examples/pagination_examples'

RSpec.describe 'Manage > Templates', type: :system do
  context 'with ajax pagination' do
    include_examples 'pagination', model: :template, klass: Template, path: 'manage/templates'
  end

  context 'when creating a new template' do
    before do
      visit '#manage/templates'

      within(:active_content) do
        find('[data-type=new]').click
      end
    end

    it 'with default attributes' do
      in_modal do
        fill_in('name', with: 'template 1')
        click_button('Submit')
      end
    end
  end

  context 'when editing an existing template' do
    let!(:template) { create(:template, :dummy_data) }

    before do
      visit '#manage/templates'

      within(:active_content) do
        find(".js-tableBody tr.item[data-id='#{template.id}']").click
      end
    end

    it 'restores stored attributes' do
      in_modal do
        expect(find('input[name="name"]').value).to eq(template.name)
        expect(find('select[name="options::ticket.formSenderType::value"] option[selected]').value).to eq(template.options['ticket.formSenderType']['value'])
        expect(find('input[name="options::ticket.title::value"]').value).to eq(template.options['ticket.title']['value'])
        expect(find('[data-name="options::article.body::value"]').text).to eq(template.options['article.body']['value'])
        expect(find('select[name="options::ticket.group_id::value"] option[selected]').value).to eq(template.options['ticket.group_id']['value'].to_s)
      end
    end

    context 'with custom attributes' do
      let(:template) { create(:template, options: { 'ticket.title': { value: 'Test' }, 'ticket.foo': { value: 'bar', 'ticket.baz': { value: nil }, 'ticket.qux': nil } }) }

      it 'ignores unknown or invalid attributes (#4316)' do
        in_modal do
          expect(find('input[name="options::ticket.title::value"]').value).to eq('Test')
          expect(find_all('select.form-control').length).to eq(2)
        end
      end
    end
  end
end
