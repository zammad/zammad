require_relative './set_up'

RSpec.configure do |config|
  config.before(:each, type: :system) do

    # start a silenced Puma as application server
    Capybara.server = :puma, { Silent: true, Host: '0.0.0.0' }

    # set the Host from gather container IP for CI runs
    if ENV['CI'].present?
      ip_address = Socket.ip_address_list.detect(&:ipv4_private?).ip_address
      host!("http://#{ip_address}")
    end

    # set custom Zammad driver (e.g. zammad_chrome) for special
    # functionalities and CI requirements
    driven_by("zammad_#{ENV.fetch('BROWSER', 'firefox')}".to_sym)
  end
end
