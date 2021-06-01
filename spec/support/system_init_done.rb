# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module SystemInitDoneHelper
  def system_init_done(state = true)
    # generally allow all calls to Setting.exists? to avoid
    # RSpec errors where a different Setting is accessed
    allow(Setting).to receive(:exists?).and_call_original

    # just mock the Setting check for `system_init_done`
    # and return the given parameter value
    expect(Setting).to receive(:exists?).with(name: 'system_init_done').and_return(state)
  end
end

RSpec.configure do |config|
  config.include SystemInitDoneHelper
end
