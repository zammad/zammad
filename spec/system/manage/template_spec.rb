# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

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

    it 'with inactive state' do
      in_modal do
        fill_in('name', with: Faker::Name.unique.name)
        find_field('active').select('inactive')
        click_button('Submit')

        await_empty_ajax_queue

        expect(Template.last.active).to be(false)
      end
    end

    it 'with cc attribute #4421' do
      cc_recipients = Array.new(2) { Faker::Internet.unique.email }.join(', ')

      in_modal do
        fill_in('name', with: Faker::Name.unique.name)
        find('.js-attributeSelector select').find(:option, 'CC').select_option
        fill_in('options::article.cc::value', with: cc_recipients)
        click_button('Submit')

        await_empty_ajax_queue
      end

      expect(Template.last.options['article.cc']['value']).to eq(cc_recipients)
    end
  end

  context 'when editing an existing template' do
    let(:template) { create(:template, :dummy_data) }

    before do

      # Wait until the test users from the template have been created.
      #   This is needed for the autocomplete fields to work correctly.
      if template.options['ticket.customer_id'] || template.options['ticket.owner_id']
        visit '/'
        wait.until { User.find(template.options['ticket.customer_id']['value']) } if template.options['ticket.customer_id']
        wait.until { User.find(template.options['ticket.owner_id']['value']) } if template.options['ticket.owner_id']
      end

      visit '#manage/templates'

      within(:active_content) do
        find(".js-tableBody tr.item[data-id='#{template.id}']").click
      end
    end

    it 'restores stored attributes' do
      in_modal do
        check_input_field_value('name', template.name)
        check_select_field_value('options::ticket.formSenderType::value', template.options['ticket.formSenderType']['value'])
        check_input_field_value('options::ticket.title::value', template.options['ticket.title']['value'])
        check_editor_field_value('options::article.body::value', template.options['article.body']['value'])
        check_select_field_value('options::ticket.group_id::value', template.options['ticket.group_id']['value'].to_s)
        check_input_field_value('options::ticket.customer_id::value_completion', template.options['ticket.customer_id']['value_completion'])
        check_input_field_value('options::ticket.owner_id::value', template.options['ticket.owner_id']['value'].to_s, visible: :all)
      end
    end

    context 'with custom attributes' do
      let(:template) do
        create(:template,
               options: {
                 'ticket.title': {
                   value: 'Test',
                 },
                 'ticket.foo':   {
                   value: 'bar',
                 },
                 'ticket.baz':   {
                   value: nil,
                 },
                 'ticket.qux':   nil,
               })
      end

      it 'ignores unknown or invalid attributes (#4316)' do
        in_modal do
          check_input_field_value('options::ticket.title::value', 'Test')
          expect(find_all('select.form-control').length).to eq(2)
        end
      end
    end

    context 'with pending till attribute (#4318)' do
      let(:template) do
        create(:template,
               options: {
                 'ticket.state_id':     {
                   value: Ticket::State.find_by(name: 'pending reminder').id.to_s
                 },
                 'ticket.pending_time': pending_time,
               })
      end

      context 'with static operator', time_zone: 'Europe/London' do
        let(:date) { 1.day.from_now }
        let(:pending_time) do
          {
            operator: 'static',
            value:    date.to_datetime.to_s,
          }
        end

        it 'restores correct values' do
          in_modal do
            check_select_field_value('options::ticket.state_id::value', template.options['ticket.state_id']['value'])
            check_select_field_value('options::ticket.pending_time::operator', template.options['ticket.pending_time']['operator'])
            check_date_field_value('options::ticket.pending_time::value', date.strftime('%m/%d/%Y'))
            check_time_field_value('options::ticket.pending_time::value', date.strftime('%H:%M'))
          end
        end
      end

      context 'with relative operator' do
        let(:pending_time) do
          {
            operator: 'relative',
            value:    '3',
            range:    'day',
          }
        end

        it 'restores correct values' do
          in_modal do
            check_select_field_value('options::ticket.state_id::value', template.options['ticket.state_id']['value'])
            check_select_field_value('options::ticket.pending_time::operator', template.options['ticket.pending_time']['operator'])
            check_select_field_value('options::ticket.pending_time::value', template.options['ticket.pending_time']['value'])
            check_select_field_value('options::ticket.pending_time::range', template.options['ticket.pending_time']['range'])
          end
        end
      end
    end

    context 'with tags attribute' do
      let(:template) do
        create(:template,
               options: {
                 'ticket.tags': tags,
               })
      end

      context 'with add operator' do
        let(:tags) do
          {
            operator: 'add',
            value:    'foo, bar',
          }
        end

        it 'restores correct values' do
          check_select_field_value('options::ticket.tags::operator', template.options['ticket.tags']['operator'])
          check_input_field_value('options::ticket.tags::value', template.options['ticket.tags']['value'], visible: :all)
        end
      end

      context 'with remove operator' do
        let(:tags) do
          {
            operator: 'remove',
            value:    'foo, bar',
          }
        end

        it 'restores correct values' do
          check_select_field_value('options::ticket.tags::operator', template.options['ticket.tags']['operator'])
          check_input_field_value('options::ticket.tags::value', template.options['ticket.tags']['value'], visible: :all)
        end
      end

      context 'without operator' do
        let(:tags) do
          {
            value: 'foo, bar',
          }
        end

        it 'defaults to add operator' do
          check_select_field_value('options::ticket.tags::operator', 'add')
          check_input_field_value('options::ticket.tags::value', template.options['ticket.tags']['value'], visible: :all)
        end
      end
    end

    context 'with cc attribute #4421' do
      let(:template) do
        create(:template,
               options: {
                 'article.cc': {
                   value: Array.new(3) { Faker::Internet.unique.email }.join(', '),
                 },
               })
      end

      it 'restores correct value' do
        check_input_field_value('options::article.cc::value', template.options['article.cc']['value'])
      end
    end

    context 'with active field' do
      let(:template) do
        create(:template,
               :dummy_data,
               active: false)
      end

      it 'shows inactive selection' do
        check_select_field_value('active', 'false')
      end

      it 'supports modifying active state' do
        find_field('active').select('active')
        click_button('Submit')

        await_empty_ajax_queue

        expect(template.reload.active).to be(true)
      end
    end
  end
end
