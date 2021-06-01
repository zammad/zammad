# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe UserDeviceLogJob, type: :job do

  let!(:user) { create(:user) }

  it 'executes user device log job' do
    expect do
      described_class.perform_now(
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.107 Safari/537.36',
        '172.0.0.1',
        user.id,
        'fingerprintABC123',
        'session',
      )
    end.to change {
      UserDevice.where(
        user_id: user.id,
      ).count
    }.by(1)
  end
end
