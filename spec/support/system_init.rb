RSpec.configure do |config|
  config.before(:suite) do
    FactoryGirl.create(:user,
                       login:     'admin',
                       firstname: 'Admin',
                       lastname:  'Admin',
                       email:     'admin@example.com',
                       password:  'admin',
                       roles:     [Role.lookup(name: 'Admin')],)
  end
end
