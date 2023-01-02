# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Default Timezone', authenticated_as: :authenticate, type: :system do
  def authenticate
    Setting.set('timezone_default', initial_timezone)

    true
  end

  def current_value
    Setting
      .find_by(name: 'timezone_default')
      .reload
      .state_current[:value]
  end

  before do
    visit "#ticket/zoom/#{Ticket.first.id}"
  end

  context 'when timezone_default is not set' do
    let(:initial_timezone) { nil }

    it 'resets timezone' do
      wait(10).until { current_value.present? }
    end
  end

  context 'when timezone_default is set' do
    let(:initial_timezone) { 'Test' }

    it 'does not change timezone' do
      sleep 10 # timezone is set with 3500ms delay

      expect(current_value).to eq('Test')
    end
  end
end
