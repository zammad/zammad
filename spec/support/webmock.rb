# allow requests to:
# - Zammad webservices
# - Google (calendar)
allowed_sites = lambda do |uri|
  ['zammad.com', 'google.com', 'exchange.example.com'].any? do |site|
    uri.host.include?(site)
  end
end
WebMock.disable_net_connect!(
  allow:           allowed_sites,
  allow_localhost: true
)
