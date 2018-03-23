module SystemInitDoneHelper
  def system_init_done(state = true)
    expect(Setting).to receive(:find_by).with(name: 'system_init_done').and_return(state)
  end
end

RSpec.configure do |config|
  config.include SystemInitDoneHelper
end
