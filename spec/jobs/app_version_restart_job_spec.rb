# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe AppVersionRestartJob, type: :job do

  let(:cmd) { '/path/to/restart_script.sh' }

  it 'executes app version restart job' do
    expect(::Kernel).to receive(:system).with(cmd)
    described_class.perform_now(cmd)
  end
end
