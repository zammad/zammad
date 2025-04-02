# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Data retention rules for object cleanup from the system with the scheduler (#4838)', type: :system do
  let(:user)         { create(:customer, organization: organization) }
  let(:organization) { create(:organization) }
  let(:ticket)       { create(:ticket, customer: user) }
  let(:article)      { create(:'ticket/article', :inbound_email, ticket: ticket) }

  before do
    travel_to 6.months.ago - 1.day
    article
    travel_back
  end

  shared_examples 'deleting object via data privacy task' do |object_name|
    before do
      visit '#manage/job'
      click 'a', text: 'New Scheduler'

      in_modal do
        fill_in 'Name', with: 'Delete users older than 6 months'
        set_select_field_value 'object', object_name

        scroll_into_view('.object_selector')

        within '.object_selector' do
          set_condition(1, 'Last contact', 'before (relative)', value: ['6'], range: ['Month(s)'])
        end

        scroll_into_view('.object_perform_action')

        within '.object_perform_action' do
          set_condition(1, 'Action', nil, value_action: 'Add a data privacy deletion task')
        end

        click_on 'Submit'
      end

      run_last_job_and_perform_last_deletion_task
    end

    it 'deletes user via data privacy task', if: object_name == 'User' do
      expect(User).not_to exist(user.id)
      expect(Organization).to exist(organization.id)
      expect(Ticket).not_to exist(ticket.id)
    end

    it 'deletes ticket via data privacy task', if: object_name == 'Ticket' do
      expect(Ticket).not_to exist(ticket.id)
      expect(User).to exist(user.id)
      expect(Organization).to exist(organization.id)
    end
  end

  context 'with user object' do
    let(:deletable) { user }

    it_behaves_like 'deleting object via data privacy task', 'User'
  end

  context 'with ticket object' do
    let(:deletable) { ticket }

    it_behaves_like 'deleting object via data privacy task', 'Ticket'
  end

  def run_last_job_and_perform_last_deletion_task
    job = Job.last

    # Workaround to always run the scheduler job without checking its executable state and if the current time applies.
    allow(job).to receive_messages(executable?: true, in_timeplan?: true)

    job.run

    DataPrivacyTask.last.perform
  end

  def set_attribute_selector(row_number, value)
    attribute_selector = find(".js-filterElement:nth-child(#{row_number}) .js-attributeSelector select")
    option = attribute_selector.find('option', text: value, exact_text: true)
    option.select_option
  end

  def set_operator_selector(row_number, value)
    operator_selector = find(".js-filterElement:nth-child(#{row_number}) .js-operator select")
    option = operator_selector.find('option', text: value, exact_text: true)
    option.select_option
  end

  def set_value_action(row_number, value)
    row_number += 1 if has_css?('.horizontal-filters .alert')
    value_action_selector = find(".js-filterElement:nth-child(#{row_number}) .js-value select")
    option = value_action_selector.find('option', text: value, exact_text: true)
    option.select_option
  end

  def set_value_selector(row_number, value)
    value_selector = find(".js-filterElement:nth-child(#{row_number}) select.js-value")
    value.each do |v|
      option = value_selector.find('option', text: v, exact_text: true)
      option.select_option
    end
  end

  def set_range_selector(row_number, value)
    range_selector = find(".js-filterElement:nth-child(#{row_number}) select.js-range")
    value.each do |v|
      option = range_selector.find('option', text: v, exact_text: true)
      option.select_option
    end
  end

  def set_condition(row_number, attribute, operator, value: nil, range: nil, value_action: nil)
    set_attribute_selector(row_number, attribute) if attribute.present?
    set_operator_selector(row_number, operator) if operator.present?

    if !value_action.nil?
      set_value_action(row_number, value_action)
    end

    return if value.nil?

    set_value_selector(row_number, value)

    return if range.nil?

    set_range_selector(row_number, range)
  end
end
