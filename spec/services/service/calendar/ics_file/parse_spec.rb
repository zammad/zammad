# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Service::Calendar::IcsFile::Parse do
  subject(:service_result) { described_class.execute(file: calendar_file) }

  let(:user)          { create(:user) }
  let(:calendar_file) { create(:store, :ics) }

  it 'parses the calendar file' do
    expect(service_result).to eq(
      events:   [{
        title:       'Test Summary',
        location:    'https://us.zoom.us/j/example?pwd=test',
        start_date:  '2021-07-27T10:30:00.000+02:00',
        end_date:    '2021-07-27T12:00:00.000+02:00',
        attendees:   ['M.bob@example.com', 'J.doe@example.com'],
        organizer:   'f.sample@example.com',
        description: 'Test description'
      }],
      filename: 'basic.ics',
      type:     'text/calendar'
    )
  end

  context 'when participants have no valid email address' do
    let(:calendar_file) do
      create(:store, :ics, data: <<~ICS)
        BEGIN:VCALENDAR
        VERSION:2.0
        BEGIN:VEVENT
        UID:participants
        DTSTAMP:20261105T090000Z
        DTSTART:20261105T100000Z
        DTEND:20261105T110000Z
        SUMMARY:Team sync
        ORGANIZER:mailto:
        ATTENDEE;CN=Bob:mailto:bob@example.com
        ATTENDEE;CN=Room booking:mailto:
        ATTENDEE;CN=Conference line:urn:uuid:3c3f4a3e-1b1a-4d53-9b8f-6b2f0b6a7a11
        ATTENDEE:mailto:
        END:VEVENT
        END:VCALENDAR
      ICS
    end

    it 'falls back to the participant name or skips the participant' do
      expect(service_result[:events].first).to include(
        title:     'Team sync',
        organizer: nil,
        attendees: ['bob@example.com', 'Room booking', 'Conference line'],
      )
    end
  end

  context 'when an event has no end date' do
    let(:calendar_file) do
      create(:store, :ics, data: <<~ICS)
        BEGIN:VCALENDAR
        VERSION:2.0
        BEGIN:VEVENT
        UID:duration
        DTSTAMP:20261104T090000Z
        DTSTART:20261111T090000Z
        DURATION:PT90M
        SUMMARY:Duration only
        END:VEVENT
        END:VCALENDAR
      ICS
    end

    it 'leaves the end date empty' do
      expect(service_result[:events].first).to include(
        title:    'Duration only',
        end_date: nil,
      )
    end
  end

  context 'when an event has no summary' do
    let(:calendar_file) do
      create(:store, :ics, data: <<~ICS)
        BEGIN:VCALENDAR
        VERSION:2.0
        BEGIN:VEVENT
        UID:description
        DTSTAMP:20261104T090000Z
        DESCRIPTION:Quarterly planning
        END:VEVENT
        END:VCALENDAR
      ICS
    end

    it 'uses the description as the title' do
      expect(service_result[:events].first).to include(
        title:       'Quarterly planning',
        description: 'Quarterly planning',
      )
    end
  end

  context 'when the calendar file is not encoded in UTF-8' do
    let(:charset)       { nil }
    let(:calendar_file) do
      create(:store, :ics,
             preferences: { 'Content-Type' => 'text/calendar', 'Charset' => charset }.compact,
             data:        <<~ICS.encode('ISO-8859-1').b)
               BEGIN:VCALENDAR
               VERSION:2.0
               BEGIN:VEVENT
               UID:latin1
               DTSTAMP:20261104T090000Z
               SUMMARY:Besprechung in München
               ATTENDEE;CN=Jürgen Müller:mailto:
               END:VEVENT
               END:VCALENDAR
             ICS
    end

    shared_examples 'parsing the converted calendar' do
      it 'parses the calendar' do
        expect(service_result[:events].first).to include(
          title:     'Besprechung in München',
          attendees: ['Jürgen Müller'],
        )
      end
    end

    context 'with a declared charset' do
      let(:charset) { 'ISO-8859-1' }

      it_behaves_like 'parsing the converted calendar'
    end

    context 'without a declared charset' do
      it_behaves_like 'parsing the converted calendar'
    end
  end

  context 'when the file is not a calendar' do
    let(:calendar_file) { create(:store, :ics, data: "\x00\xFF\xFEnot a calendar".b) }

    it 'returns no events' do
      expect(service_result[:events]).to be_empty
    end
  end
end
