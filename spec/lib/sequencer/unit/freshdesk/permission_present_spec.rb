# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Sequencer::Unit::Freshdesk::PermissionPresent, sequencer: :unit do

  context 'when checking the permission to Freshdesk' do

    let(:params) do
      {
        dry_run:    false,
        import_job: instance_double(ImportJob),
        field_map:  {},
        id_map:     {},
      }
    end

    let(:response_ok)        { Net::HTTPOK.new(1.0, '200', 'OK') }
    let(:response_forbidden) { Net::HTTPForbidden.new(1.0, '403', 'Forbidden') }

    it 'check for correct permission' do
      allow(described_class).to receive(:perform_request).with(any_args).and_return(response_ok)
      expect(process(params)).to eq({ permission_present: true })
    end

    it 'check for forbidden permission' do
      allow(described_class).to receive(:perform_request).with(any_args).and_return(response_forbidden)
      expect(process(params)).to eq({ permission_present: false })
    end
  end
end
