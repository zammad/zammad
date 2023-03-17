# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe TimeplanCalculation do
  subject(:instance) { described_class.new(timeplan, timezone) }

  let(:timezone) { nil }

  describe '#contains?' do
    context 'without a valid timeplan' do
      let(:timeplan) { {} }

      it { is_expected.not_to be_contains(Time.zone.now) }
    end

    context 'with monday 09:20' do
      let(:timeplan) { { 'days' => { 'Mon' => true }, 'hours' => { '9' => true }, 'minutes' => { '20' => true } } }

      it { is_expected.to be_contains(Time.zone.parse('2020-12-28 09:20')) }
      it { is_expected.to be_contains(Time.zone.parse('2020-12-21 09:20')) }
      it { is_expected.not_to be_contains(Time.zone.parse('2020-12-21 10:20')) }
      it { is_expected.not_to be_contains(Time.zone.parse('2020-12-21 9:10')) }
      it { is_expected.not_to be_contains(Time.zone.parse('2020-12-22 9:20')) }
      it { is_expected.not_to be_contains(Time.zone.parse('2020-12-20 9:20')) }
    end

    context 'with monday and tuesday 09:20' do
      let(:timeplan) { { 'days' => { 'Mon' => true, 'Tue' => true }, 'hours' => { '9' => true }, 'minutes' => { '20' => true } } }

      it { is_expected.to be_contains(Time.zone.parse('2020-12-28 09:20')) }
      it { is_expected.to be_contains(Time.zone.parse('2020-12-21 09:20')) }
      it { is_expected.not_to be_contains(Time.zone.parse('2020-12-21 10:20')) }
      it { is_expected.not_to be_contains(Time.zone.parse('2020-12-21 9:10')) }
      it { is_expected.to be_contains(Time.zone.parse('2020-12-22 9:20')) }
      it { is_expected.not_to be_contains(Time.zone.parse('2020-12-20 9:20')) }
    end

    context 'with monday 09:20 and 10:20' do
      let(:timeplan) { { 'days' => { 'Mon' => true }, 'hours' => { '9' => true, '10' => true }, 'minutes' => { '20' => true } } }

      it { is_expected.to be_contains(Time.zone.parse('2020-12-28 09:20')) }
      it { is_expected.to be_contains(Time.zone.parse('2020-12-21 09:20')) }
      it { is_expected.to be_contains(Time.zone.parse('2020-12-21 10:20')) }
      it { is_expected.not_to be_contains(Time.zone.parse('2020-12-21 9:10')) }
      it { is_expected.not_to be_contains(Time.zone.parse('2020-12-22 9:20')) }
      it { is_expected.not_to be_contains(Time.zone.parse('2020-12-20 9:20')) }
    end

    context 'with monday 09:20 and 9:10' do
      let(:timeplan) { { 'days' => { 'Mon' => true }, 'hours' => { '9' => true }, 'minutes' => { '20' => true, '10' => true } } }

      it { is_expected.to be_contains(Time.zone.parse('2020-12-28 09:20')) }
      it { is_expected.to be_contains(Time.zone.parse('2020-12-21 09:20')) }
      it { is_expected.not_to be_contains(Time.zone.parse('2020-12-21 10:20')) }
      it { is_expected.to be_contains(Time.zone.parse('2020-12-21 9:10')) }
      it { is_expected.not_to be_contains(Time.zone.parse('2020-12-22 9:20')) }
      it { is_expected.not_to be_contains(Time.zone.parse('2020-12-20 9:20')) }
    end

    context 'with monday 09:00 and time zone' do
      let(:timeplan) { { 'days' => { 'Mon' => true }, 'hours' => { '1' => true }, 'minutes' => { '0' => true } } }
      let(:timezone) { 'Europe/Vilnius' }

      it { is_expected.to be_contains(Time.use_zone('Europe/Vilnius') { Time.zone.parse('2020-12-21 01:00') }) }
      it { is_expected.to be_contains(Time.zone.parse('2020-12-20 23:00')) }
    end
  end

  describe '#next_at' do
    context 'without a valid timeplan' do
      let(:timeplan) { {} }

      it { expect(instance.next_at(Time.zone.now)).to be_nil }
    end

    context 'with monday 09:20' do
      let(:timeplan) { { 'days' => { 'Mon' => true }, 'hours' => { '9' => true }, 'minutes' => { '20' => true } } }

      it { expect(instance.next_at(Time.zone.parse('2020-12-28 09:31'))).to eq(Time.zone.parse('2021-01-04 09:20')) }
      it { expect(instance.next_at(Time.zone.parse('2020-12-28 09:30'))).to eq(Time.zone.parse('2021-01-04 09:20')) }
      it { expect(instance.next_at(Time.zone.parse('2020-12-28 09:20'))).to eq(Time.zone.parse('2020-12-28 09:20')) }
      it { expect(instance.next_at(Time.zone.parse('2020-12-21 09:21'))).to eq(Time.zone.parse('2020-12-21 09:20')) }
      it { expect(instance.next_at(Time.zone.parse('2020-12-21 09:35'))).to eq(Time.zone.parse('2020-12-28 09:20')) }
      it { expect(instance.next_at(Time.zone.parse('2020-12-21 10:20'))).to eq(Time.zone.parse('2020-12-28 09:20')) }
      it { expect(instance.next_at(Time.zone.parse('2020-12-21 10:21'))).to eq(Time.zone.parse('2020-12-28 09:20')) }
      it { expect(instance.next_at(Time.zone.parse('2020-12-21 9:10'))).to eq(Time.zone.parse('2020-12-21 09:20')) }
      it { expect(instance.next_at(Time.zone.parse('2020-12-22 9:20'))).to eq(Time.zone.parse('2020-12-28 09:20')) }
      it { expect(instance.next_at(Time.zone.parse('2020-12-20 9:20'))).to eq(Time.zone.parse('2020-12-21 09:20')) }
    end

    context 'with monday and tuesday 09:20' do
      let(:timeplan) { { 'days' => { 'Mon' => true, 'Tue' => true }, 'hours' => { '9' => true }, 'minutes' => { '20' => true } } }

      it { expect(instance.next_at(Time.zone.parse('2020-12-28 09:30'))).to eq(Time.zone.parse('2020-12-29 09:20')) }
      it { expect(instance.next_at(Time.zone.parse('2020-12-29 09:30'))).to eq(Time.zone.parse('2021-01-04 09:20')) }
      it { expect(instance.next_at(Time.zone.parse('2020-12-21 09:25'))).to eq(Time.zone.parse('2020-12-21 09:20')) }
      it { expect(instance.next_at(Time.zone.parse('2020-12-21 09:35'))).to eq(Time.zone.parse('2020-12-22 09:20')) }
      it { expect(instance.next_at(Time.zone.parse('2020-12-21 10:20'))).to eq(Time.zone.parse('2020-12-22 09:20')) }
      it { expect(instance.next_at(Time.zone.parse('2020-12-21 10:21'))).to eq(Time.zone.parse('2020-12-22 09:20')) }
      it { expect(instance.next_at(Time.zone.parse('2020-12-21 9:10'))).to eq(Time.zone.parse('2020-12-21 09:20')) }
      it { expect(instance.next_at(Time.zone.parse('2020-12-22 9:30'))).to eq(Time.zone.parse('2020-12-28 09:20')) }
      it { expect(instance.next_at(Time.zone.parse('2020-12-20 9:20'))).to eq(Time.zone.parse('2020-12-21 09:20')) }
    end

    context 'with monday 09:20 and 10:20' do
      let(:timeplan) { { 'days' => { 'Mon' => true }, 'hours' => { '9' => true, '10' => true }, 'minutes' => { '20' => true } } }

      it { expect(instance.next_at(Time.zone.parse('2020-12-28 09:30'))).to eq(Time.zone.parse('2020-12-28 10:20')) }
      it { expect(instance.next_at(Time.zone.parse('2020-12-21 09:30'))).to eq(Time.zone.parse('2020-12-21 10:20')) }
      it { expect(instance.next_at(Time.zone.parse('2020-12-21 09:35'))).to eq(Time.zone.parse('2020-12-21 10:20')) }
      it { expect(instance.next_at(Time.zone.parse('2020-12-21 08:07'))).to eq(Time.zone.parse('2020-12-21 09:20')) }
      it { expect(instance.next_at(Time.zone.parse('2020-12-21 10:30'))).to eq(Time.zone.parse('2020-12-28 09:20')) }
      it { expect(instance.next_at(Time.zone.parse('2020-12-21 10:31'))).to eq(Time.zone.parse('2020-12-28 09:20')) }
      it { expect(instance.next_at(Time.zone.parse('2020-12-21 9:10'))).to eq(Time.zone.parse('2020-12-21 09:20')) }
      it { expect(instance.next_at(Time.zone.parse('2020-12-21 9:47'))).to eq(Time.zone.parse('2020-12-21 10:20')) }
      it { expect(instance.next_at(Time.zone.parse('2020-12-22 9:20'))).to eq(Time.zone.parse('2020-12-28 09:20')) }
      it { expect(instance.next_at(Time.zone.parse('2020-12-20 9:30'))).to eq(Time.zone.parse('2020-12-21 09:20')) }
    end

    context 'with monday 09:30 and 9:10' do
      let(:timeplan) { { 'days' => { 'Mon' => true }, 'hours' => { '9' => true }, 'minutes' => { '30' => true, '10' => true } } }

      it { expect(instance.next_at(Time.zone.parse('2020-12-28 09:40'))).to eq(Time.zone.parse('2021-01-04 09:10')) }
      it { expect(instance.next_at(Time.zone.parse('2020-12-21 09:40'))).to eq(Time.zone.parse('2020-12-28 09:10')) }
      it { expect(instance.next_at(Time.zone.parse('2020-12-21 09:30'))).to eq(Time.zone.parse('2020-12-21 09:30')) }
      it { expect(instance.next_at(Time.zone.parse('2020-12-21 09:25'))).to eq(Time.zone.parse('2020-12-21 09:30')) }
      it { expect(instance.next_at(Time.zone.parse('2020-12-21 09:35'))).to eq(Time.zone.parse('2020-12-21 09:30')) }
      it { expect(instance.next_at(Time.zone.parse('2020-12-21 09:45'))).to eq(Time.zone.parse('2020-12-28 09:10')) }
      it { expect(instance.next_at(Time.zone.parse('2020-12-21 08:07'))).to eq(Time.zone.parse('2020-12-21 09:10')) }
      it { expect(instance.next_at(Time.zone.parse('2020-12-21 10:20'))).to eq(Time.zone.parse('2020-12-28 09:10')) }
      it { expect(instance.next_at(Time.zone.parse('2020-12-21 10:21'))).to eq(Time.zone.parse('2020-12-28 09:10')) }
      it { expect(instance.next_at(Time.zone.parse('2020-12-21 9:10'))).to eq(Time.zone.parse('2020-12-21 09:10')) }
      it { expect(instance.next_at(Time.zone.parse('2020-12-21 9:20'))).to eq(Time.zone.parse('2020-12-21 09:30')) }
      it { expect(instance.next_at(Time.zone.parse('2020-12-22 9:20'))).to eq(Time.zone.parse('2020-12-28 09:10')) }
      it { expect(instance.next_at(Time.zone.parse('2020-12-20 9:20'))).to eq(Time.zone.parse('2020-12-21 09:10')) }
    end

    context 'with monday 09:00 and time zone' do
      let(:timezone) { 'Europe/Vilnius' }
      let(:timeplan) { { 'days' => { 'Mon' => true }, 'hours' => { '1' => true }, 'minutes' => { '0' => true } } }

      it 'calculates time respecting time zone' do
        from = Time.use_zone('Europe/Vilnius') { Time.zone.parse('2020-12-21 01:15') }
        to   = Time.use_zone('Europe/Vilnius') { Time.zone.parse('2020-12-28 01:00') }

        expect(instance.next_at(from)).to eq(to)
      end

      it 'calculates time converting to time zone' do
        from = Time.zone.parse('2020-12-20 23:10')
        to   = Time.use_zone('Europe/Vilnius') { Time.zone.parse('2020-12-28 01:00') }

        expect(instance.next_at(from)).to eq(to)
      end
    end
  end

  describe '#previous_at' do
    context 'without a valid timeplan' do
      let(:timeplan) { {} }

      it { expect(instance.previous_at(Time.zone.now)).to be_nil }
    end

    context 'with monday 09:20' do
      let(:timeplan) { { 'days' => { 'Mon' => true }, 'hours' => { '9' => true }, 'minutes' => { '20' => true } } }

      it { expect(instance.previous_at(Time.zone.parse('2020-12-28 09:31'))).to eq(Time.zone.parse('2020-12-28 09:20')) }
      it { expect(instance.previous_at(Time.zone.parse('2020-12-28 09:30'))).to eq(Time.zone.parse('2020-12-28 09:20')) }
      it { expect(instance.previous_at(Time.zone.parse('2020-12-28 09:20'))).to eq(Time.zone.parse('2020-12-28 09:20')) }
      it { expect(instance.previous_at(Time.zone.parse('2020-12-21 09:21'))).to eq(Time.zone.parse('2020-12-21 09:20')) }
      it { expect(instance.previous_at(Time.zone.parse('2020-12-21 09:35'))).to eq(Time.zone.parse('2020-12-21 09:20')) }
      it { expect(instance.previous_at(Time.zone.parse('2020-12-21 10:20'))).to eq(Time.zone.parse('2020-12-21 09:20')) }
      it { expect(instance.previous_at(Time.zone.parse('2020-12-21 10:21'))).to eq(Time.zone.parse('2020-12-21 09:20')) }
      it { expect(instance.previous_at(Time.zone.parse('2020-12-21 9:10'))).to eq(Time.zone.parse('2020-12-14 09:20')) }
      it { expect(instance.previous_at(Time.zone.parse('2020-12-22 9:20'))).to eq(Time.zone.parse('2020-12-21 09:20')) }
      it { expect(instance.previous_at(Time.zone.parse('2020-12-20 9:20'))).to eq(Time.zone.parse('2020-12-14 09:20')) }
    end

    context 'with monday 23:00' do
      let(:timeplan) { { 'days' => { 'Mon' => true }, 'hours' => { '23' => true }, 'minutes' => { '0' => true } } }

      it { expect(instance.previous_at(Time.zone.parse('2020-12-29 00:00'))).to eq(Time.zone.parse('2020-12-28 23:00')) }
    end

    context 'with monday and tuesday 09:20' do
      let(:timeplan) { { 'days' => { 'Mon' => true, 'Tue' => true }, 'hours' => { '9' => true }, 'minutes' => { '20' => true } } }

      it { expect(instance.previous_at(Time.zone.parse('2020-12-28 09:30'))).to eq(Time.zone.parse('2020-12-28 09:20')) }
      it { expect(instance.previous_at(Time.zone.parse('2020-12-29 09:30'))).to eq(Time.zone.parse('2020-12-29 09:20')) }
      it { expect(instance.previous_at(Time.zone.parse('2020-12-21 09:25'))).to eq(Time.zone.parse('2020-12-21 09:20')) }
      it { expect(instance.previous_at(Time.zone.parse('2020-12-21 09:35'))).to eq(Time.zone.parse('2020-12-21 09:20')) }
      it { expect(instance.previous_at(Time.zone.parse('2020-12-22 8:20'))).to eq(Time.zone.parse('2020-12-21 09:20')) }
      it { expect(instance.previous_at(Time.zone.parse('2020-12-22 8:21'))).to eq(Time.zone.parse('2020-12-21 09:20')) }
      it { expect(instance.previous_at(Time.zone.parse('2020-12-21 9:30'))).to eq(Time.zone.parse('2020-12-21 09:20')) }
      it { expect(instance.previous_at(Time.zone.parse('2020-12-22 9:10'))).to eq(Time.zone.parse('2020-12-21 09:20')) }
      it { expect(instance.previous_at(Time.zone.parse('2020-12-23 9:10'))).to eq(Time.zone.parse('2020-12-22 09:20')) }
    end

    context 'with monday 09:20 and 10:20' do
      let(:timeplan) { { 'days' => { 'Mon' => true }, 'hours' => { '9' => true, '10' => true }, 'minutes' => { '20' => true } } }

      it { expect(instance.previous_at(Time.zone.parse('2020-12-29 09:10'))).to eq(Time.zone.parse('2020-12-28 10:20')) }
      it { expect(instance.previous_at(Time.zone.parse('2020-12-21 09:30'))).to eq(Time.zone.parse('2020-12-21 09:20')) }
      it { expect(instance.previous_at(Time.zone.parse('2020-12-21 09:35'))).to eq(Time.zone.parse('2020-12-21 09:20')) }
      it { expect(instance.previous_at(Time.zone.parse('2020-12-22 08:07'))).to eq(Time.zone.parse('2020-12-21 10:20')) }
      it { expect(instance.previous_at(Time.zone.parse('2020-12-21 10:30'))).to eq(Time.zone.parse('2020-12-21 10:20')) }
      it { expect(instance.previous_at(Time.zone.parse('2020-12-21 10:31'))).to eq(Time.zone.parse('2020-12-21 10:20')) }
      it { expect(instance.previous_at(Time.zone.parse('2020-12-21 9:10'))).to eq(Time.zone.parse('2020-12-14 10:20')) }
      it { expect(instance.previous_at(Time.zone.parse('2020-12-21 9:47'))).to eq(Time.zone.parse('2020-12-21 09:20')) }
      it { expect(instance.previous_at(Time.zone.parse('2020-12-22 9:20'))).to eq(Time.zone.parse('2020-12-21 10:20')) }
      it { expect(instance.previous_at(Time.zone.parse('2020-12-23 9:30'))).to eq(Time.zone.parse('2020-12-21 10:20')) }
    end

    context 'with monday 09:30 and 9:10' do
      let(:timeplan) { { 'days' => { 'Mon' => true }, 'hours' => { '9' => true }, 'minutes' => { '30' => true, '10' => true } } }

      it { expect(instance.previous_at(Time.zone.parse('2020-12-28 09:40'))).to eq(Time.zone.parse('2020-12-28 09:30')) }
      it { expect(instance.previous_at(Time.zone.parse('2020-12-28 07:40'))).to eq(Time.zone.parse('2020-12-21 09:30')) }
      it { expect(instance.previous_at(Time.zone.parse('2020-12-21 09:30'))).to eq(Time.zone.parse('2020-12-21 09:30')) }
      it { expect(instance.previous_at(Time.zone.parse('2020-12-21 09:25'))).to eq(Time.zone.parse('2020-12-21 09:10')) }
      it { expect(instance.previous_at(Time.zone.parse('2020-12-21 09:35'))).to eq(Time.zone.parse('2020-12-21 09:30')) }
      it { expect(instance.previous_at(Time.zone.parse('2020-12-21 05:45'))).to eq(Time.zone.parse('2020-12-14 09:30')) }
      it { expect(instance.previous_at(Time.zone.parse('2020-12-21 14:07'))).to eq(Time.zone.parse('2020-12-21 09:30')) }
      it { expect(instance.previous_at(Time.zone.parse('2020-12-28 10:20'))).to eq(Time.zone.parse('2020-12-28 09:30')) }
      it { expect(instance.previous_at(Time.zone.parse('2020-12-28 10:21'))).to eq(Time.zone.parse('2020-12-28 09:30')) }
      it { expect(instance.previous_at(Time.zone.parse('2020-12-21 9:10'))).to eq(Time.zone.parse('2020-12-21 09:10')) }
      it { expect(instance.previous_at(Time.zone.parse('2020-12-21 9:20'))).to eq(Time.zone.parse('2020-12-21 09:10')) }
      it { expect(instance.previous_at(Time.zone.parse('2020-12-22 9:20'))).to eq(Time.zone.parse('2020-12-21 09:30')) }
      it { expect(instance.previous_at(Time.zone.parse('2020-12-25 9:20'))).to eq(Time.zone.parse('2020-12-21 09:30')) }
    end

    context 'with monday 01:00 and time zone' do
      let(:timezone) { 'Europe/Vilnius' }
      let(:timeplan) { { 'days' => { 'Mon' => true }, 'hours' => { '1' => true }, 'minutes' => { '0' => true } } }

      it 'calculates time respecting time zone' do
        from = Time.use_zone('Europe/Vilnius') { Time.zone.parse('2020-12-21 00:15') }
        to   = Time.use_zone('Europe/Vilnius') { Time.zone.parse('2020-12-14 01:00') }

        expect(instance.previous_at(from)).to eq(to)
      end

      it 'calculates time converting to time zone' do
        from = Time.zone.parse('2020-12-20 23:10')
        to   = Time.use_zone('Europe/Vilnius') { Time.zone.parse('2020-12-21 01:00') }

        expect(instance.previous_at(from)).to eq(to)
      end
    end
  end

  describe 'legacy tests moved from Job model' do
    let(:job)      { create(:job, :never_on) }
    let(:timeplan) { job.timeplan }
    let(:time)     { Time.current }

    context 'when the current day, hour, and minute all match true values in #timeplan' do
      it 'for Symbol/Integer keys returns true' do
        timeplan[:days].transform_keys!(&:to_sym)[time.strftime('%a').to_sym] = true
        timeplan[:hours].transform_keys!(&:to_i)[time.hour] = true
        timeplan[:minutes].transform_keys!(&:to_i)[time.min.floor(-1)] = true

        expect(instance.contains?(time)).to be(true)
      end

      it 'for String keys returns true' do
        timeplan[:days].transform_keys!(&:to_s)[time.strftime('%a')] = true
        timeplan[:hours].transform_keys!(&:to_s)[time.hour.to_s] = true
        timeplan[:minutes].transform_keys!(&:to_s)[time.min.floor(-1).to_s] = true

        expect(instance.contains?(time)).to be(true)
      end
    end

    context 'when the current day does not match a true value in #timeplan' do
      it 'for Symbol/Integer keys returns false' do
        timeplan[:days].transform_keys!(&:to_sym).transform_values! { true }[time.strftime('%a').to_sym] = false
        timeplan[:hours].transform_keys!(&:to_i)[time.hour] = true
        timeplan[:minutes].transform_keys!(&:to_i)[time.min.floor(-1)] = true

        expect(instance.contains?(time)).to be(false)
      end

      it 'for String keys returns false' do
        timeplan[:days].transform_keys!(&:to_s).transform_values! { true }[time.strftime('%a')] = false
        timeplan[:hours].transform_keys!(&:to_s)[time.hour.to_s] = true
        timeplan[:minutes].transform_keys!(&:to_s)[time.min.floor(-1).to_s] = true

        expect(instance.contains?(time)).to be(false)
      end
    end

    context 'when the current hour does not match a true value in #timeplan' do
      it 'for Symbol/Integer keys returns false' do
        timeplan[:days].transform_keys!(&:to_sym)[time.strftime('%a').to_sym] = true
        timeplan[:hours].transform_keys!(&:to_i).transform_values! { true }[time.hour] = false
        timeplan[:minutes].transform_keys!(&:to_i)[time.min.floor(-1)] = true

        expect(instance.contains?(time)).to be(false)
      end

      it 'for String keys returns false' do
        timeplan[:days].transform_keys!(&:to_s)[time.strftime('%a')] = true
        timeplan[:hours].transform_keys!(&:to_s).transform_values! { true }[time.hour.to_s] = false
        timeplan[:minutes].transform_keys!(&:to_s)[time.min.floor(-1).to_s] = true

        expect(instance.contains?(time)).to be(false)
      end
    end

    context 'when the current minute does not match a true value in #timeplan' do
      it 'for Symbol/Integer keys returns false' do
        timeplan[:days].transform_keys!(&:to_sym)[time.strftime('%a').to_sym] = true
        timeplan[:hours].transform_keys!(&:to_i)[time.hour] = true
        timeplan[:minutes].transform_keys!(&:to_i).transform_values! { true }[time.min.floor(-1)] = false

        expect(instance.contains?(time)).to be(false)
      end

      it 'for String keys returns false' do
        timeplan[:days].transform_keys!(&:to_s)[time.strftime('%a')] = true
        timeplan[:hours].transform_keys!(&:to_s)[time.hour.to_s] = true
        timeplan[:minutes].transform_keys!(&:to_s).transform_values! { true }[time.min.floor(-1).to_s] = false

        expect(instance.contains?(time)).to be(false)
      end
    end
  end
end
