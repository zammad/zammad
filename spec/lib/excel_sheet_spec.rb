# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ExcelSheet do

  describe '.timestamp_in_localtime' do

    let(:document) { described_class.new(title: 'some title', header: [], records: [], timezone: 'Europe/Berlin', locale: 'de-de') }

    it 'does convert UTC timestamp to local system based timestamp' do
      expect(document.timestamp_in_localtime(Time.parse('2019-08-08T01:00:05Z').in_time_zone)).to eq('2019-08-08 03:00:05')
    end

  end
end
