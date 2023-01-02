# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Kayako import', db_strategy: :reset, integration: true, required_envs: %w[IMPORT_KAYAKO_ENDPOINT IMPORT_KAYAKO_ENDPOINT_PASSWORD IMPORT_KAYAKO_ENDPOINT_USERNAME], use_vcr: true do # rubocop:disable RSpec/DescribeClass
  let(:job) { ImportJob.last }

  before do
    Setting.set('import_kayako_endpoint', ENV['IMPORT_KAYAKO_ENDPOINT'])
    Setting.set('import_kayako_endpoint_password', ENV['IMPORT_KAYAKO_ENDPOINT_PASSWORD'])
    Setting.set('import_kayako_endpoint_username', ENV['IMPORT_KAYAKO_ENDPOINT_USERNAME'])
    Setting.set('import_mode', true)
    Setting.set('system_init_done', false)

    VCR.use_cassette 'kayako_import' do
      ImportJob.create(name: 'Import::Kayako').start
    end
  end

  context 'when performing the full Kayako import' do
    let(:job) { ImportJob.last }
    let(:expected_stats) do
      {
        'Groups'        => {
          'skipped'     => 0,
          'created'     => 4,
          'updated'     => 0,
          'unchanged'   => 0,
          'failed'      => 0,
          'deactivated' => 0,
          'sum'         => 4,
          'total'       => 4,
        },
        'Users'         => {
          'skipped'     => 0,
          'created'     => 7,
          'updated'     => 0,
          'unchanged'   => 0,
          'failed'      => 0,
          'deactivated' => 0,
          'sum'         => 7,
          'total'       => 7,
        },
        'Organizations' => {
          'skipped'     => 0,
          'created'     => 2,
          'updated'     => 1,
          'unchanged'   => 0,
          'failed'      => 0,
          'deactivated' => 0,
          'sum'         => 3,
          'total'       => 3,
        },
        'Tickets'       => {
          'skipped'     => 0,
          'created'     => 4,
          'updated'     => 1,
          'unchanged'   => 0,
          'failed'      => 0,
          'deactivated' => 0,
          'sum'         => 5,
          'total'       => 5,
        },
      }
    end

    it 'imports the correct number of expected objects' do
      expect(job.result).to eq expected_stats
    end
  end
end
