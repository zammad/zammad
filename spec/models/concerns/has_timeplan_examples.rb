# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'HasTimeplan' do
  subject { create(described_class.name.underscore) }

  describe '#in_timeplan?' do
    before do
      subject.timeplan = { days: { Mon: true }, hours: { 0 => true }, minutes: { 0 => true } }
    end

    it 'checks in selected time zone' do
      Setting.set 'timezone_default', 'Europe/Vilnius'

      expect(subject).to be_in_timeplan Time.zone.parse('2020-12-27 22:00')
    end

    it 'checks in UTC' do
      expect(subject).to be_in_timeplan Time.zone.parse('2020-12-28 00:00')
    end
  end
end
