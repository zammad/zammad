# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

# Ported from test/browser/manage_test.rb: updating and deleting a sla persists
#   across a reload. Kept separate from sla_spec.rb, whose ensure_websocket hook
#   is not needed for this flow.
RSpec.describe 'Manage > Sla > Update and delete', type: :system do
  let(:sla) { create(:sla, name: 'some sla', first_response_time: 61) }

  before do
    sla

    visit 'manage/slas'
  end

  it 'updates name and first response time and deletes the sla afterwards' do
    click '.js-edit'

    in_modal do
      fill_in :name, with: 'some sla update'

      # The time field carries an input mask whose keystroke handling differs
      #   between browsers - set the value via script and trigger the events
      #   the widget listens to.
      field = find('input[name="first_response_time_in_text"]')
      field.execute_script("this.value = '2:01'; $(this).trigger('change').trigger('blur')")

      expect(field.value).to match(%r{^0?2:01$})

      click '.js-submit'
    end

    expect(page).to have_text('some sla update')
    expect(sla.reload).to have_attributes(name: 'some sla update', first_response_time: 121)

    click '.js-delete'

    in_modal do
      click 'button.js-submit'
    end

    expect(page).to have_no_text('some sla update')

    page.refresh

    expect(page).to have_no_text('some sla update')
  end
end
