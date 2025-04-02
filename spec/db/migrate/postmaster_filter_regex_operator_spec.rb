# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe PostmasterFilterRegexOperator, type: :db_migration do
  context 'when postmaster filters needs to be updated' do
    let!(:filter) do
      create(:postmaster_filter,
             match: {
               'subject' => {
                 'operator' => 'contains',
                 'value'    => 'dummy*',
               },
               'to'      => {
                 'operator' => 'contains',
                 'value'    => 'regex:test.*',
               },
               'from'    => {
                 'operator' => 'contains not',
                 'value'    => 'x',
               },
               'cc'      => {
                 'operator' => 'contains not',
                 'value'    => 'regex:^abc.*z$',
               },
             })
    end

    it 'does migrate the postmaster filters' do
      migrate

      expect(filter.reload.match).to eq({
                                          'subject' => {
                                            'operator' => 'contains',
                                            'value'    => 'dummy*',
                                          },
                                          'to'      => {
                                            'operator' => 'matches regex',
                                            'value'    => 'test.*',
                                          },
                                          'from'    => {
                                            'operator' => 'contains not',
                                            'value'    => 'x',
                                          },
                                          'cc'      => {
                                            'operator' => 'does not match regex',
                                            'value'    => '^abc.*z$',
                                          },
                                        })
    end
  end

  context 'when monitoring settings needs to be updated' do
    before do
      %w[nagios icinga monit].each do |monitoring_name|
        setting_name = "#{monitoring_name}_sender"

        Setting.set(setting_name, 'regex:test.*')
      end
    end

    it 'the regex prefix was removed' do
      migrate

      %w[nagios icinga monit].each do |monitoring_name|
        setting_name = "#{monitoring_name}_sender"

        expect(Setting.get(setting_name)).to eq('test.*')
      end
    end
  end
end
