# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

RSpec.shared_examples 'UserPerformsGeoLookup' do

  it 'can only be loaded for User' do
    expect(described_class).to eq User
  end

  it 'performs geo lookup' do

    # Mock the geo lookup as it requires an API key.
    allow(Service::GeoLocation).to receive(:geocode).with('Marienstraße 18, 10117, Berlin, Germany').and_return([10.0, 20.0])

    user = create(described_class.name.underscore, street: 'Marienstraße 18', zip: '10117', city: 'Berlin', country: 'Germany')

    expect(user.preferences).to include(lat: 10.0, lng: 20.0)
  end
end
