TCR.configure do |config|
  config.cassette_library_dir = 'test/data/tcr_cassettes'
  config.hook_tcp_ports = [389] # LDAP
  config.format = 'yaml'
end
