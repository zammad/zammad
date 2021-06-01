# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe TriggerWebhookJob::RecordPayload do

  describe '.generate' do

    subject(:generate) { described_class.generate(record) }

    context 'when generator backend exists' do

      let(:record) { build(:ticket) }
      let(:backend) { TriggerWebhookJob::RecordPayload::Ticket }

      it 'initializes backend instance and sends generate' do
        instance = double()
        allow(instance).to receive(:generate)
        allow(backend).to receive(:new).and_return(instance)

        generate

        expect(instance).to have_received(:generate)
      end
    end

    context 'when given record is nil' do

      let(:record) { nil }

      it 'returns an empty hash' do
        expect(generate).to eq({})
      end
    end

    context 'when given record is not supported' do

      let(:record) { build(:sla) }

      it 'raises an exception' do
        expect { generate }.to raise_exception(NameError)
      end
    end
  end
end
