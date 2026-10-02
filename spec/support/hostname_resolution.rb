# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module HostnameResolutionHelper
  # Pins what the hostname of a URL resolves to. A request whose address is validated before it is
  # sent resolves the hostname first, which WebMock does not intercept - and a documentation domain
  # resolves to nothing.
  def stub_hostname_resolution(url, ip: '203.0.113.10')
    allow(IPSocket).to receive(:getaddress).with(URI.parse(url).host).and_return(ip)
  end
end

RSpec.configure do |config|
  config.include HostnameResolutionHelper
end
