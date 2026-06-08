# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::User::OutOfOffice do
  subject(:service_result) do
    described_class
      .with_current_user(agent)
      .execute(enabled:, start_at:, end_at:, replacement:, text:)
  end

  let(:agent)       { create(:agent) }
  let(:replacement) { create(:agent) }
  let(:enabled)     { true }
  let(:start_at)    { Date.parse('2011-02-03') }
  let(:end_at)      { Date.parse('2011-03-03') }
  let(:text)        { 'Out of office message' }

  it 'sets and enables Out of Office' do
    service_result

    expect(agent.reload)
      .to have_attributes(
        out_of_office:                true,
        out_of_office_start_at:       Date.parse('2011-02-03'),
        out_of_office_end_at:         Date.parse('2011-03-03'),
        out_of_office_replacement_id: replacement.id,
        preferences:                  include(out_of_office_text: 'Out of office message')
      )
  end

  context 'when disabling Out of Office' do
    let(:enabled)      { false }
    let(:start_at)     { nil }
    let(:end_at)       { nil }
    let(:replacement)  { nil }
    let(:text)         { nil }

    it 'disables Out of Office' do
      service_result

      expect(agent.reload)
        .to have_attributes(out_of_office: false)
    end
  end

  context 'when given data is invalid' do
    let(:replacement) { nil }

    it 'raises an error' do
      expect { service_result }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
