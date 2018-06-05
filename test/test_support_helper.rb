# automatically require all helpers in test/support
Dir[Rails.root.join('test', 'support', '**', '*.rb')].each { |f| require f }
