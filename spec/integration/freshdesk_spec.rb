# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

#
# The purpose of this integration test is to verify that the API generally works.
# Individual import steps are tested in spec/lib/sequencer.
#

RSpec.describe 'Freshdesk import', db_strategy: :reset, integration: true, required_envs: %w[IMPORT_FRESHDESK_ENDPOINT IMPORT_FRESHDESK_ENDPOINT_KEY IMPORT_FRESHDESK_ENDPOINT_SUBDOMAIN], use_vcr: true do # rubocop:disable RSpec/DescribeClass

  before do
    Setting.set('import_freshdesk_endpoint', ENV['IMPORT_FRESHDESK_ENDPOINT'])
    Setting.set('import_freshdesk_endpoint_key', ENV['IMPORT_FRESHDESK_ENDPOINT_KEY'])
    Setting.set('import_mode', true)
    Setting.set('system_init_done', false)

    VCR.use_cassette 'freshdesk_import' do
      ImportJob.create(name: 'Import::Freshdesk').start
    end
  end

  context 'when performing the full Freshdesk import' do

    let(:job) { ImportJob.last }
    let(:expected_stats) do
      {
        'Groups'        => {
          'skipped'     => 0,
          'created'     => 9,
          'updated'     => 0,
          'unchanged'   => 0,
          'failed'      => 0,
          'deactivated' => 0,
          'sum'         => 9,
          'total'       => 9,
        },
        'Users'         => {
          'skipped'     => 0,
          'created'     => 19,
          'updated'     => 0,
          'unchanged'   => 0,
          'failed'      => 0,
          'deactivated' => 0,
          'sum'         => 19,
          'total'       => 19,
        },
        'Organizations' => {
          'skipped'     => 0,
          'created'     => 0,
          'updated'     => 1,
          'unchanged'   => 0,
          'failed'      => 0,
          'deactivated' => 0,
          'sum'         => 1,
          'total'       => 1,
        },
        'Tickets'       => {
          'skipped'     => 0,
          'created'     => 13,
          'updated'     => 0,
          'unchanged'   => 0,
          'failed'      => 0,
          'deactivated' => 0,
          'sum'         => 13,
          'total'       => 13,
        },
      }
    end

    it 'imports the correct number of expected objects' do
      expect(job.result).to eq expected_stats
    end
  end

end
