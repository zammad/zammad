# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

#
# The purpose of this integration test is to verify that the API generally works.
# Individual import steps are tested in spec/lib/sequencer.
#

RSpec.describe 'Freshdesk import', type: :integration, use_vcr: true, db_strategy: :reset do # rubocop:disable RSpec/DescribeClass

  before do

    if !ENV['IMPORT_FRESHDESK_ENDPOINT']
      raise "ERROR: Need IMPORT_FRESHDESK_ENDPOINT - hint IMPORT_FRESHDESK_ENDPOINT='https://example.freshdesk.com/api/v2'"
    end
    if !ENV['IMPORT_FRESHDESK_ENDPOINT_KEY']
      raise "ERROR: Need IMPORT_FRESHDESK_ENDPOINT_KEY - hint IMPORT_FRESHDESK_ENDPOINT_KEY='01234567899876543210'"
    end

    Setting.set('import_freshdesk_endpoint', ENV['IMPORT_FRESHDESK_ENDPOINT'])
    Setting.set('import_freshdesk_endpoint_key', ENV['IMPORT_FRESHDESK_ENDPOINT_KEY'])
    Setting.set('import_mode', true)
    Setting.set('system_init_done', false)

    VCR.configure do |c|
      %w[
        IMPORT_FRESHDESK_ENDPOINT
        IMPORT_FRESHDESK_ENDPOINT_KEY
        IMPORT_FRESHDESK_ENDPOINT_SUBDOMAIN
      ].each do |env_key|
        c.filter_sensitive_data("<#{env_key}>") { ENV[env_key] }
      end

      # The API key is used only inside the base64 encoded Basic Auth string, so mask that as well.
      %w[
        IMPORT_FRESHDESK_ENDPOINT_BASIC_AUTH
      ].each do |env_key|
        c.filter_sensitive_data("<#{env_key}>") { Base64.encode64( "#{ENV['IMPORT_FRESHDESK_ENDPOINT_KEY']}:X" ).chomp }
      end
    end

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
