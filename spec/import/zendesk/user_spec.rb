require 'rails_helper'

# required due to some of rails autoloading issues
require 'import/zendesk/user'

RSpec.describe Import::Zendesk::User do

  it 'create_or_updates user' do

    user = double(
      id:               1337,
      name:             'Example User',
      email:            'user@example.com',
      phone:            '+49-123-345673',
      suspended:        false,
      notes:            'Nice guy',
      verified:         true,
      organization_id:  42,
      last_login_at:    DateTime.yesterday,
      photo:            double(content_url: 'https://img.remote.tld/w40293402zz394eed'),
      user_fields:      [],
    )

    expected_structure = {
      login:           user.email,
      firstname:       user.name,
      email:           user.email,
      phone:           user.phone,
      password:        '',
      active:          !user.suspended,
      groups:          [1, 2, 3],
      roles:           [3],
      note:            user.notes,
      verified:        user.verified,
      organization_id: 101,
      last_login:      user.last_login_at,
      image_source:    user.photo.content_url,
      updated_by_id:   1,
      created_by_id:   1
    }

    local_user = double(id: 31_337)

    expect(Import::Zendesk::User::Group).to receive(:for).with(user).and_return(expected_structure[:groups])
    expect(Import::Zendesk::User::Role).to receive(:for).with(user).and_return(expected_structure[:roles])
    expect(Import::Zendesk::OrganizationFactory).to receive(:local_id).with( user.organization_id ).and_return(expected_structure[:organization_id])

    expect(::User).to receive(:create_or_update).with( expected_structure ).and_return(local_user)

    created_instance = described_class.new(user)

    expect(created_instance).to respond_to(:id)
    expect(created_instance.id).to eq(local_user.id)

    expect(created_instance).to respond_to(:zendesk_id)
    expect(created_instance.zendesk_id).to eq(user.id)
  end

  it 'imports id as login if no email address is available' do

    user = double(
      id:               1337,
      name:             'Example User',
      email:            nil,
      phone:            '+49-123-345673',
      suspended:        false,
      notes:            'Nice guy',
      verified:         true,
      organization_id:  42,
      last_login_at:    DateTime.yesterday,
      photo:            double(content_url: 'https://img.remote.tld/w40293402zz394eed'),
      user_fields:      [],
    )

    expected_structure = {
      login:           user.id.to_s,
      firstname:       user.name,
      email:           user.email,
      phone:           user.phone,
      password:        '',
      active:          !user.suspended,
      groups:          [1, 2, 3],
      roles:           [3],
      note:            user.notes,
      verified:        user.verified,
      organization_id: 101,
      last_login:      user.last_login_at,
      image_source:    user.photo.content_url,
      updated_by_id:   1,
      created_by_id:   1
    }

    local_user = double(id: 31_337)

    expect(Import::Zendesk::User::Group).to receive(:for).with(user).and_return(expected_structure[:groups])
    expect(Import::Zendesk::User::Role).to receive(:for).with(user).and_return(expected_structure[:roles])
    expect(Import::Zendesk::OrganizationFactory).to receive(:local_id).with( user.organization_id ).and_return(expected_structure[:organization_id])

    expect(::User).to receive(:create_or_update).with( expected_structure ).and_return(local_user)

    created_instance = described_class.new(user)

    expect(created_instance).to respond_to(:id)
    expect(created_instance.id).to eq(local_user.id)

    expect(created_instance).to respond_to(:zendesk_id)
    expect(created_instance.zendesk_id).to eq(user.id)
  end

  it 'handles import user credentials and privileges specially' do

    user = double(
      id:               1337,
      name:             'Example User',
      email:            'user@example.com',
      phone:            '+49-123-345673',
      suspended:        false,
      notes:            'Nice guy',
      verified:         true,
      organization_id:  42,
      last_login_at:    DateTime.yesterday,
      photo:            double(content_url: 'https://img.remote.tld/w40293402zz394eed'),
      user_fields:      [],
    )

    password = 'apikeyprovidedfortheimportbytheuser'

    expected_structure = {
      login:           user.email,
      firstname:       user.name,
      email:           user.email,
      phone:           user.phone,
      password:        password,
      active:          !user.suspended,
      groups:          [1, 2, 3],
      roles:           [1, 2],
      note:            user.notes,
      verified:        user.verified,
      organization_id: 101,
      last_login:      user.last_login_at,
      image_source:    user.photo.content_url,
      updated_by_id:   1,
      created_by_id:   1
    }

    local_user = double(id: 31_337)

    expect(Import::Zendesk::User::Group).to receive(:for).with(user).and_return(expected_structure[:groups])
    expect(Import::Zendesk::User::Role).to receive(:map).with(user, 'admin').and_return(expected_structure[:roles])
    expect(Import::Zendesk::OrganizationFactory).to receive(:local_id).with( user.organization_id ).and_return(expected_structure[:organization_id])

    expect(Setting).to receive(:get).with('import_zendesk_endpoint_username').twice.and_return(user.email)
    expect(Setting).to receive(:get).with('import_zendesk_endpoint_key').and_return(password)

    expect(::User).to receive(:create_or_update).with( expected_structure ).and_return(local_user)

    created_instance = described_class.new(user)

    expect(created_instance).to respond_to(:id)
    expect(created_instance.id).to eq(local_user.id)

    expect(created_instance).to respond_to(:zendesk_id)
    expect(created_instance.zendesk_id).to eq(user.id)
  end
end
