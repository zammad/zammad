# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# allow requests to:
# - Zammad webservices
# - Google (calendar)
# - exchange.example.com (MS Exchange TCR mocks)
# - localhost (Selenium server control)
allowed_sites = lambda do |uri|
  ['zammad.com', 'google.com', 'exchange.example.com'].any? do |site|
    uri.host.include?(site)
  end
end
WebMock.disable_net_connect!(
  allow:           allowed_sites,
  allow_localhost: true
)
