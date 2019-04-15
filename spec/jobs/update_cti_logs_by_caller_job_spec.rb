require 'rails_helper'

RSpec.describe UpdateCtiLogsByCallerJob, type: :job do
  let(:phone)     { '1234567890' }
  let!(:logs)     { create_list(:cti_log, 5, direction: :in, from: phone) }
  let(:log_prefs) { logs.each(&:reload).map(&:preferences) }

  it 'accepts a phone number' do
    expect { described_class.perform_now(phone) }
      .not_to raise_error
  end

  context 'with no user matching provided phone number' do
    it 'updates Cti::Logs from that number with "preferences" => {}' do
      described_class.perform_now(phone)

      expect(log_prefs).to all(be_empty)
    end
  end

  context 'with existing user matching provided phone number' do
    before { create(:user, phone: phone) }

    it 'updates Cti::Logs from that number with valid "preferences" hash' do
      described_class.perform_now(phone)

      expect(log_prefs).to all(include('from' => a_kind_of(Array)))
    end
  end
end
