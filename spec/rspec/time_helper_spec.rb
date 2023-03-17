# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'TimeHelperCache', time_zone: 'Europe/London' do
  context 'with frontend_relative_month' do
    before do
      freeze_time
      travel_to DateTime.parse(datestamp)
    end

    context "when it's the 1st day of the month" do
      let(:datestamp) { '2023-01-01T12:00:00.000Z' }

      it 'matches ECMAScript results' do
        expect([
                 frontend_relative_month(Time.current, 1),
                 frontend_relative_month(Time.current, 2),
                 frontend_relative_month(Time.current, 3),
                 frontend_relative_month(Time.current, 4),
                 frontend_relative_month(Time.current, 5),
                 frontend_relative_month(Time.current, 6),
                 frontend_relative_month(Time.current, 7),
                 frontend_relative_month(Time.current, 8),
                 frontend_relative_month(Time.current, 9),
                 frontend_relative_month(Time.current, 10),
                 frontend_relative_month(Time.current, 11),
                 frontend_relative_month(Time.current, 12),
               ]).to eq([
                          '2023-02-01T12:00:00.000Z',
                          '2023-03-01T12:00:00.000Z',
                          '2023-04-01T11:00:00.000Z',
                          '2023-05-01T11:00:00.000Z',
                          '2023-06-01T11:00:00.000Z',
                          '2023-07-01T11:00:00.000Z',
                          '2023-08-01T11:00:00.000Z',
                          '2023-09-01T11:00:00.000Z',
                          '2023-10-01T11:00:00.000Z',
                          '2023-11-01T12:00:00.000Z',
                          '2023-12-01T12:00:00.000Z',
                          '2024-01-01T12:00:00.000Z',
                        ])
      end
    end

    context "when it's the 28th day of the month" do
      let(:datestamp) { '2023-01-28T12:00:00.000Z' }

      it 'matches ECMAScript result' do
        expect([
                 frontend_relative_month(Time.current, 1),
                 frontend_relative_month(Time.current, 2),
                 frontend_relative_month(Time.current, 3),
                 frontend_relative_month(Time.current, 4),
                 frontend_relative_month(Time.current, 5),
                 frontend_relative_month(Time.current, 6),
                 frontend_relative_month(Time.current, 7),
                 frontend_relative_month(Time.current, 8),
                 frontend_relative_month(Time.current, 9),
                 frontend_relative_month(Time.current, 10),
                 frontend_relative_month(Time.current, 11),
                 frontend_relative_month(Time.current, 12),
               ]).to eq([
                          '2023-02-28T12:00:00.000Z',
                          '2023-03-28T11:00:00.000Z',
                          '2023-04-28T11:00:00.000Z',
                          '2023-05-28T11:00:00.000Z',
                          '2023-06-28T11:00:00.000Z',
                          '2023-07-28T11:00:00.000Z',
                          '2023-08-28T11:00:00.000Z',
                          '2023-09-28T11:00:00.000Z',
                          '2023-10-28T11:00:00.000Z',
                          '2023-11-28T12:00:00.000Z',
                          '2023-12-28T12:00:00.000Z',
                          '2024-01-28T12:00:00.000Z',
                        ])
      end
    end

    context "when it's the 29th day of the month" do
      let(:datestamp) { '2023-01-29T12:00:00.000Z' }

      it 'matches ECMAScript result' do
        expect([
                 frontend_relative_month(Time.current, 1),
                 frontend_relative_month(Time.current, 2),
                 frontend_relative_month(Time.current, 3),
                 frontend_relative_month(Time.current, 4),
                 frontend_relative_month(Time.current, 5),
                 frontend_relative_month(Time.current, 6),
                 frontend_relative_month(Time.current, 7),
                 frontend_relative_month(Time.current, 8),
                 frontend_relative_month(Time.current, 9),
                 frontend_relative_month(Time.current, 10),
                 frontend_relative_month(Time.current, 11),
                 frontend_relative_month(Time.current, 12),
               ]).to eq([
                          '2023-03-01T12:00:00.000Z',
                          '2023-03-29T11:00:00.000Z',
                          '2023-04-29T11:00:00.000Z',
                          '2023-05-29T11:00:00.000Z',
                          '2023-06-29T11:00:00.000Z',
                          '2023-07-29T11:00:00.000Z',
                          '2023-08-29T11:00:00.000Z',
                          '2023-09-29T11:00:00.000Z',
                          '2023-10-29T12:00:00.000Z',
                          '2023-11-29T12:00:00.000Z',
                          '2023-12-29T12:00:00.000Z',
                          '2024-01-29T12:00:00.000Z',
                        ])
      end
    end

    context "when it's the 30th day of the month" do
      let(:datestamp) { '2023-01-30T12:00:00.000Z' }

      it 'matches ECMAScript result' do
        expect([
                 frontend_relative_month(Time.current, 1),
                 frontend_relative_month(Time.current, 2),
                 frontend_relative_month(Time.current, 3),
                 frontend_relative_month(Time.current, 4),
                 frontend_relative_month(Time.current, 5),
                 frontend_relative_month(Time.current, 6),
                 frontend_relative_month(Time.current, 7),
                 frontend_relative_month(Time.current, 8),
                 frontend_relative_month(Time.current, 9),
                 frontend_relative_month(Time.current, 10),
                 frontend_relative_month(Time.current, 11),
                 frontend_relative_month(Time.current, 12),
               ]).to eq([
                          '2023-03-02T12:00:00.000Z',
                          '2023-03-30T11:00:00.000Z',
                          '2023-04-30T11:00:00.000Z',
                          '2023-05-30T11:00:00.000Z',
                          '2023-06-30T11:00:00.000Z',
                          '2023-07-30T11:00:00.000Z',
                          '2023-08-30T11:00:00.000Z',
                          '2023-09-30T11:00:00.000Z',
                          '2023-10-30T12:00:00.000Z',
                          '2023-11-30T12:00:00.000Z',
                          '2023-12-30T12:00:00.000Z',
                          '2024-01-30T12:00:00.000Z',
                        ])
      end
    end

    context "when it's the 31st day of the month" do
      let(:datestamp) { '2023-01-31T12:00:00.000Z' }

      it 'matches ECMAScript result' do
        expect([
                 frontend_relative_month(Time.current, 1),
                 frontend_relative_month(Time.current, 2),
                 frontend_relative_month(Time.current, 3),
                 frontend_relative_month(Time.current, 4),
                 frontend_relative_month(Time.current, 5),
                 frontend_relative_month(Time.current, 6),
                 frontend_relative_month(Time.current, 7),
                 frontend_relative_month(Time.current, 8),
                 frontend_relative_month(Time.current, 9),
                 frontend_relative_month(Time.current, 10),
                 frontend_relative_month(Time.current, 11),
                 frontend_relative_month(Time.current, 12),
               ]).to eq([
                          '2023-03-03T12:00:00.000Z',
                          '2023-03-31T11:00:00.000Z',
                          '2023-05-01T11:00:00.000Z',
                          '2023-05-31T11:00:00.000Z',
                          '2023-07-01T11:00:00.000Z',
                          '2023-07-31T11:00:00.000Z',
                          '2023-08-31T11:00:00.000Z',
                          '2023-10-01T11:00:00.000Z',
                          '2023-10-31T12:00:00.000Z',
                          '2023-12-01T12:00:00.000Z',
                          '2023-12-31T12:00:00.000Z',
                          '2024-01-31T12:00:00.000Z',
                        ])
      end
    end
  end
end
