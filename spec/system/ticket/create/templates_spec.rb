# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket Create > Templates', time_zone: 'Europe/London', type: :system do
  context 'when applying ticket templates' do
    let(:agent)                       { create(:agent, groups: [permitted_group]) }
    let(:permitted_group)             { create(:group) }
    let(:unpermitted_group)           { create(:group) }
    let!(:template_unpermitted_group) { create(:template, :dummy_data, group: unpermitted_group, owner: agent) }
    let!(:template_permitted_group)   { create(:template, :dummy_data, group: permitted_group, owner: agent) }

    before { visit 'ticket/create' }

    # Regression test for issue #2424 - Unavailable ticket template attributes get applied
    it 'unavailable attributes do not get applied', authenticated_as: :agent do
      use_template(template_unpermitted_group)
      expect(page).to have_select('owner_id', selected: agent.fullname)
      expect(find('[name="group_id"]', visible: :all).value).not_to eq unpermitted_group.id.to_s
    end

    it 'available attributes get applied', authenticated_as: :agent do
      use_template(template_permitted_group)
      expect(find('[name="group_id"]', visible: :all).value).to eq permitted_group.id.to_s
      expect(find('[name="owner_id"]', visible: :all).value).to eq agent.id.to_s
    end

    # The QUnit tests check App.TicketCreate.applyTemplateTags for every operator.
    context 'with tag values' do
      let(:template) { create(:template, options: { 'ticket.tags': { value: 'foo, bar', operator: 'add' } }) }

      it 'replaces tags in a clean form' do
        use_template(template)
        check_tokens_field_value('tags', %w[foo bar], visible: :all)
      end

      it 'merges with existing tags in a dirty form' do
        set_tokens_field_value('tags', %w[baz qux foo])
        use_template(template)
        check_tokens_field_value('tags', %w[baz qux foo bar])
      end
    end

  end

  describe 'Ticket templates do not save the owner attribute #4175' do
    let(:agent)     { create(:agent, groups: [Group.first]) }
    let!(:template) { create(:template, :dummy_data, group: Group.first, owner: agent) }

    before do
      visit 'ticket/create'

      # Wait for the initial taskbar update to finish
      taskbar_timestamp = Taskbar.last.updated_at
      wait.until { Taskbar.last.updated_at != taskbar_timestamp }
    end

    it 'does set owners properly by templates and taskbars' do
      use_template(template)
      expect(page).to have_select('owner_id', selected: agent.fullname)
      wait.until { Taskbar.last.state['owner_id'].to_i == agent.id }
      refresh
      expect(page).to have_select('owner_id', selected: agent.fullname)
    end
  end

  describe 'Ticket templates resets article body #2434' do
    let!(:template1) { create(:template, :dummy_data, title: 'template 1', body: 'body 1') }
    let!(:template2) { create(:template, :dummy_data, title: 'template 2', body: 'body 2') }

    before do
      visit 'ticket/create'
    end

    it 'preserves text input from the user' do
      taskbar_timestamp = Taskbar.last.updated_at

      set_editor_field_value('body', 'foobar')

      wait.until { Taskbar.last.updated_at != taskbar_timestamp }

      use_template(template1)
      check_input_field_value('title', 'template 1')
      check_editor_field_value('body', 'foobar')
    end

    it 'allows easy switching between templates' do
      use_template(template1)
      check_input_field_value('title', 'template 1')
      check_editor_field_value('body', 'body 1')

      use_template(template2)
      check_input_field_value('title', 'template 2')
      check_editor_field_value('body', 'body 2')

      taskbar_timestamp = Taskbar.last.updated_at

      set_editor_field_value('body', 'foobar')

      wait.until { Taskbar.last.updated_at != taskbar_timestamp }

      # This time body value should be left as-is
      use_template(template1)
      check_input_field_value('title', 'template 1')
      check_editor_field_value('body', 'foobar')
    end
  end

  describe 'Ticket templates are missing pending till option #4318' do

    shared_examples 'check datetime field' do

      shared_examples 'calculated datetime value' do

        it 'applies correct datetime value' do
          use_template(template, without_taskbar: true)

          check_date_field_value(field, date.strftime('%m/%d/%Y'))
          check_time_field_value(field, date.strftime('%H:%M'))
        end

      end

      context 'with static operator' do
        let(:operator)       { 'static' }
        let(:date)           { 3.days.from_now }
        let(:template_value) { date.to_datetime.to_s }

        it_behaves_like 'calculated datetime value'
      end

      # The QUnit tests check App.ViewHelpers.relative_time for every range.
      context 'with relative operator' do
        let(:operator)       { 'relative' }
        let(:range)          { 'hour' }
        let(:value)          { [*(1..48)].sample }
        let(:template_value) { value.to_s }

        # Javascript disregards DST switch and simply adds hours.
        # Rails Time does respect DST switch and this causes off-by-one errors around DST.
        # Time looses time zone and DST details when converted to DateTime.
        # Then DateTime#advance matches Javascript DST ignorance.
        let(:date) { DateTime.current.advance(hours: value) }

        it_behaves_like 'calculated datetime value'
      end
    end

    shared_examples 'check date field' do
      let(:date)           { 5.days.from_now }
      let(:template_value) { date.to_datetime.to_s }

      it 'applies correct date value' do
        use_template(template, without_taskbar: true)

        check_date_field_value(field, date.strftime('%m/%d/%Y'))
      end
    end

    describe 'pending till support' do
      let(:field) { 'pending_time' }
      let(:template) do
        create(:template,
               options: {
                 'ticket.state_id': {
                   value: Ticket::State.find_by(name: 'pending reminder').id.to_s,
                 },
                 "ticket.#{field}": {
                   value:    template_value,
                   operator: operator,
                   range:    (range if defined? range),
                 }
               })
      end

      before do
        freeze_time
        template
        visit '/'
        browser_travel_to Time.current
        visit 'ticket/create'
      end

      include_examples 'check datetime field'
    end

    describe 'custom attribute support' do
      let(:template) do
        create(:template,
               options: {
                 "ticket.#{field}": {
                   value:    template_value,
                   operator: (operator if defined? operator),
                   range:    (range if defined? range),
                 }
               })
      end

      before :all do # rubocop:disable RSpec/BeforeAfterAll
        screens = {
          create_middle: {
            'ticket.agent' => {
              shown: true,
            },
          },
        }

        create(:object_manager_attribute_date, name: 'test_date', display: 'test_date', screens: screens)
        create(:object_manager_attribute_datetime, name: 'test_datetime', display: 'test_datetime', screens: screens)
        ObjectManager::Attribute.migration_execute # rubocop:disable Zammad/ExistsDbStrategy
      end

      after :all do # rubocop:disable RSpec/BeforeAfterAll
        ObjectManager::Attribute.where(name: %w[test_date test_datetime]).destroy_all
      end

      before do
        freeze_time
        template
        visit '/'
        browser_travel_to Time.current
        visit 'ticket/create'
      end

      context 'with date attribute' do
        let(:field) { 'test_date' }

        include_examples 'check date field'
      end

      context 'with datetime attribute' do
        let(:field) { 'test_datetime' }

        include_examples 'check datetime field'
      end
    end
  end

  describe 'Ticket templates are missing active flag #4381' do
    let!(:active_template)   { create(:template, :dummy_data, active: true) }
    let!(:inactive_template) { create(:template, :dummy_data, active: false) }

    before do
      visit 'ticket/create'
    end

    it 'filters active templates only' do
      expect(find('#form-template select[name="id"]')).to have_css('option', text: active_template.name).and(have_no_css('option', text: inactive_template.name))
    end
  end

  describe 'CC field cannot be customized in the new ticket templates #4421', authenticated_as: :agent do
    let(:group)         { create(:group) }
    let(:agent)         { create(:agent, groups: [group]) }
    let(:customer)      { create(:customer) }
    let(:cc_recipients) { Array.new(3) { Faker::Internet.unique.email }.join(', ') }
    let(:ticket_title)  { Faker::Name.unique.name_with_middle }
    let!(:template) do
      create(:template,
             options: {
               'ticket.title':          {
                 value: ticket_title,
               },
               'ticket.customer_id':    {
                 value:            customer.id,
                 value_completion: "#{customer.firstname} #{customer.lastname} <#{customer.email}>",
               },
               'ticket.group_id':       {
                 value: group.id,
               },
               'ticket.formSenderType': {
                 value: form_sender_type,
               },
               'article.cc':            {
                 value: cc_recipients,
               },
               'article.body':          {
                 value: Faker::Hacker.say_something_smart,
               },
             })
    end

    before do
      visit 'ticket/create'
    end

    context 'with email article type' do
      let(:form_sender_type) { 'email-out' }

      it 'applies configured cc value' do
        use_template(template)

        expect(page).to have_css('label', text: 'CC')

        check_input_field_value('cc', cc_recipients, visible: :all)

        click '.js-submit'

        wait.until { Ticket.last.title == ticket_title }
        expect(Ticket.last.articles.first).to have_attributes(cc: cc_recipients)
      end
    end

    context 'with phone article type' do
      let(:form_sender_type) { 'phone-out' }

      it 'ignores configured cc value' do
        use_template(template)

        expect(page).to have_no_css('label', text: 'CC')

        click '.js-submit'

        wait.until { Ticket.last.title == ticket_title }
        expect(Ticket.last.articles.first).not_to have_attributes(cc: cc_recipients)
      end
    end
  end

  describe 'Date field value of a ticket template is not added into a new ticket #4864', authenticated_as: :authenticate, db_strategy: :reset do
    let(:field_name) { SecureRandom.uuid }
    let(:field) do
      create(:object_manager_attribute_date, :required_screen, name: field_name, display: field_name)
      ObjectManager::Attribute.migration_execute
    end
    let(:template) do
      create(:template, :dummy_data).tap do |template|
        template.update(options: template.options.merge("ticket.#{field_name}" => { 'operator' => 'relative', 'value' => '1', 'range' => 'day' }))
      end
    end

    def authenticate
      field
      true
    end

    before do
      visit 'ticket/create'
      use_template(template)
    end

    it 'does create a date with a relative template value' do
      click '.js-submit'
      expect(Ticket.last).to have_attributes(field_name => 1.day.from_now.to_date)
    end
  end
end
