# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sequencer::Unit::Kayako::Connected, sequencer: :unit do

  context 'when checking the connection to Kayako' do

    let(:params) do
      {
        dry_run:    false,
        import_job: instance_double(ImportJob),
        field_map:  {},
        id_map:     {},
      }
    end

    let(:response_ok)           { Net::HTTPOK.new(1.0, '200', 'OK') }
    let(:response_unauthorized) { Net::HTTPUnauthorized.new(1.0, '401', 'Unauthorized') }

    it 'check for correct connection' do
      allow(described_class).to receive(:perform_request).with(any_args).and_return(response_ok)
      expect(process(params)).to eq({ connected: true })
    end

    it 'check for unauthorized connection' do
      allow(described_class).to receive(:perform_request).with(any_args).and_return(response_unauthorized)
      expect(process(params)).to eq({ connected: false })
    end
  end
end
