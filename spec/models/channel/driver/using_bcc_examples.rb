# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'using BCC' do
  context 'when BCC is configured' do
    let(:bcc_email) { 'bcc@example.org' }

    before do
      Setting.set('system_bcc', bcc_email)
    end

    context 'when it is a notification email' do
      it 'does not add BCC to the message' do
        expect_any_instance_of(described_class)
          .to receive(:deliver_mail)
          .with(hash_excluding(bcc: bcc_email), any_args)

        channel.deliver({}, true)
      end
    end

    context 'when it is a communication email' do
      it 'adds BCC to the message' do
        expect_any_instance_of(described_class)
          .to receive(:deliver_mail)
          .with(hash_including(bcc: bcc_email), any_args)

        channel.deliver({}, false)
      end
    end
  end
end
