# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Zendesk import', integration: true, use_vcr: true, db_strategy: :reset, required_envs: %w[IMPORT_ZENDESK_ENDPOINT IMPORT_ZENDESK_ENDPOINT_KEY IMPORT_ZENDESK_ENDPOINT_USERNAME] do # rubocop:disable RSpec/DescribeClass
  let(:job) { ImportJob.last }

  before do
    Setting.set('import_zendesk_endpoint', ENV['IMPORT_ZENDESK_ENDPOINT'])
    Setting.set('import_zendesk_endpoint_key', ENV['IMPORT_ZENDESK_ENDPOINT_KEY'])
    Setting.set('import_zendesk_endpoint_username', ENV['IMPORT_ZENDESK_ENDPOINT_USERNAME'])
    Setting.set('import_mode', true)
    Setting.set('system_init_done', false)

    VCR.use_cassette 'zendesk_import' do
      ImportJob.create(name: 'Import::Zendesk').start
    end
  end

  context 'when performing the full Zendesk import' do
    let(:job) { ImportJob.last }
    let(:expected_stats) do
      {
        'Groups'        => {
          'skipped'     => 0,
          'created'     => 2,
          'updated'     => 0,
          'unchanged'   => 0,
          'failed'      => 0,
          'deactivated' => 0,
          'sum'         => 2,
          'total'       => 2,
        },
        'Users'         => {
          'skipped'     => 0,
          'created'     => 142,
          'updated'     => 1,
          'unchanged'   => 0,
          'failed'      => 0,
          'deactivated' => 0,
          'sum'         => 143,
          'total'       => 143,
        },
        'Organizations' => {
          'skipped'     => 0,
          'created'     => 1,
          'updated'     => 0,
          'unchanged'   => 1,
          'failed'      => 0,
          'deactivated' => 0,
          'sum'         => 2,
          'total'       => 2,
        },
        'Tickets'       => {
          'skipped'     => 1,
          'created'     => 142,
          'updated'     => 2,
          'unchanged'   => 0,
          'failed'      => 0,
          'deactivated' => 0,
          'sum'         => 145,
          'total'       => 145,
        },
      }
    end

    it 'imports the correct number of expected objects' do
      expect(job.result).to eq expected_stats
    end
  end
end
