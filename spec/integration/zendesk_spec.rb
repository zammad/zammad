# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Zendesk import', db_strategy: :reset, integration: true, required_envs: %w[IMPORT_ZENDESK_ENDPOINT IMPORT_ZENDESK_ENDPOINT_KEY IMPORT_ZENDESK_ENDPOINT_USERNAME], use_vcr: true do # rubocop:disable RSpec/DescribeClass
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
          'skipped'     => 0,
          'created'     => 142,
          'updated'     => 2,
          'unchanged'   => 0,
          'failed'      => 0,
          'deactivated' => 0,
          'sum'         => 144,
          'total'       => 144,
        },
      }
    end

    it 'imports the correct number of expected objects' do
      expect(job.result).to eq expected_stats
    end
  end
end
