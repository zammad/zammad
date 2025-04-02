# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::User::OutOfOffice do
  let(:agent)       { create(:agent) }
  let(:replacement) { create(:agent) }

  it 'sets and enables Out of Office' do
    described_class
      .new(agent,
           enabled:     true,
           start_at:    Date.parse('2011-02-03'),
           end_at:      Date.parse('2011-03-03'),
           replacement: replacement,
           text:        'Out of office message')
      .execute

    expect(agent)
      .to have_attributes(
        out_of_office:                true,
        out_of_office_start_at:       Date.parse('2011-02-03'),
        out_of_office_end_at:         Date.parse('2011-03-03'),
        out_of_office_replacement_id: replacement.id,
        preferences:                  include(out_of_office_text: 'Out of office message')
      )
  end

  it 'disables Out of Office' do
    described_class
      .new(agent, enabled: false)
      .execute

    expect(agent)
      .to have_attributes(out_of_office: false)
  end

  it 'raises an error if given data is invalid' do
    service = described_class
      .new(agent,
           enabled:  true,
           start_at: Date.parse('2011-02-03'),
           end_at:   Date.parse('2011-03-03'))

    expect { service.execute }
      .to raise_error(ActiveRecord::RecordInvalid)
  end
end
