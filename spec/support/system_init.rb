RSpec.configure do |config|
  config.before(:suite) do

    email = 'admin@example.com'
    if !::User.exists?(email: email)
      FactoryGirl.create(:user,
                         login:     'admin',
                         firstname: 'Admin',
                         lastname:  'Admin',
                         email:     email,
                         password:  'admin',
                         roles:     [Role.lookup(name: 'Admin')],)
    end
  end
end
