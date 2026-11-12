# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Calendar::Ical::Parse do
  subject(:execute) { described_class.execute(body:) }

  let(:body) { Rails.root.join("test/data/calendar/#{fixture}").read }

  # the event window is relative to the current time
  before { travel_to Time.zone.parse('2017-08-24T01:04:44Z0') }

  context 'with a recurring all-day event' do
    let(:fixture) { 'calendar1.ics' }

    it 'returns one day per occurrence, from one year before to three years after' do
      expect(execute).to eq(
        '2016-12-24' => 'Christmas1',
        '2017-12-24' => 'Christmas1',
        '2018-12-24' => 'Christmas1',
        '2019-12-24' => 'Christmas1',
        '2020-12-24' => 'Christmas1',
      )
    end

    context 'when the host time zone is east of UTC', time_zone: 'Europe/Berlin' do
      it 'keeps the occurrences on their day' do
        expect(execute.keys).to eq(%w[2016-12-24 2017-12-24 2018-12-24 2019-12-24 2020-12-24])
      end
    end
  end

  context 'with one-time and n-time (recurring) events' do
    let(:fixture) { 'calendar3.ics' }

    it 'returns a day for each of them' do
      expect(execute).to eq(
        '2016-12-24' => 'Christmas1',
        '2016-12-26' => 'day3',
        '2016-12-28' => 'day5',
        '2017-01-26' => 'day3',
        '2017-02-26' => 'day3',
        '2017-03-26' => 'day3',
        '2017-04-26' => 'day3',
        '2017-12-24' => 'Christmas1',
        '2018-12-24' => 'Christmas1',
        '2019-12-24' => 'Christmas1',
        '2020-12-24' => 'Christmas1',
      )
    end
  end

  context 'with timed recurring events' do
    let(:fixture) { 'calendar4.ics' }

    it 'returns each occurrence on its day in the event time zone' do
      expect(execute).to eq(
        '2017-01-05' => 'night shift',
        '2017-01-12' => 'custom zone shift',
        '2017-01-19' => 'evening shift',
        '2017-02-05' => 'night shift',
        '2017-02-12' => 'custom zone shift',
        '2017-02-19' => 'evening shift',
        '2017-03-05' => 'night shift',
        '2017-04-05' => 'night shift',
      )
    end
  end

  context 'when the feed contains the same day twice' do
    let(:fixture) { 'calendar_duplicate_check.ics' }

    it 'returns the day once' do
      expect(execute).to eq(
        '2019-01-01' => 'Neujahrstag',
        '2019-04-22' => 'Ostermontag',
      )
    end
  end

  context 'without a calendar in the feed' do
    let(:body) { '' }

    it 'returns no events' do
      expect(execute).to eq({})
    end
  end
end
