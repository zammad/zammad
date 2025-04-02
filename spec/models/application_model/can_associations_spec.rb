# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ApplicationModel::CanAssociations, type: :model do
  describe '.association_name_to_id_convert' do
    it 'converts has many users association by login' do
      user   = create(:user)
      params = { name: 'org', members: [user.login] }

      converted_params = Organization.association_name_to_id_convert(params)

      expect(converted_params)
        .to eq({
                 name:       'org',
                 member_ids: [user.id]
               })
    end

    it 'converts has many users association by email' do
      user   = create(:user)
      params = { name: 'org', members: [user.email] }

      converted_params = Organization.association_name_to_id_convert(params)

      expect(converted_params)
        .to eq({
                 name:       'org',
                 member_ids: [user.id]
               })
    end

    it 'keeps IDs for has many associations if given in non _id field' do
      params           = { name: 'org', members: [123] }
      converted_params = Organization.association_name_to_id_convert(params)

      expect(converted_params)
        .to eq({
                 name:    'org',
                 members: [123]
               })
    end

    it 'raises error if has many association is given non-existant identifier' do
      params = { name: 'org', members: ['nonexistantstring'] }

      expect { Organization.association_name_to_id_convert(params) }
        .to raise_error Exceptions::UnprocessableEntity, %r{No lookup value found}
    end

    it 'converts non-user has many association by name' do
      token  = create(:token)
      params = { email: 'email@example.org', tokens: [token.name] }

      converted_params = User.association_name_to_id_convert(params)

      expect(converted_params)
        .to eq({
                 email:     'email@example.org',
                 token_ids: [token.id]
               })
    end

    it 'does not convert named association if ids are given' do
      user   = create(:user)
      params = { name: 'org', members: [user.login], member_ids: [512] }

      converted_params = Organization.association_name_to_id_convert(params)

      expect(converted_params).to eq(params)
    end

    it 'converts belongs to users association by login' do
      user   = create(:user)
      params = { name: 'token', user: user.login }

      converted_params = Token.association_name_to_id_convert(params)

      expect(converted_params)
        .to eq({
                 name:    'token',
                 user_id: user.id
               })
    end

    it 'converts belongs to users association by email' do
      user   = create(:user)
      params = { name: 'token', user: user.email }

      converted_params = Token.association_name_to_id_convert(params)

      expect(converted_params).to eq({
                                       name:    'token',
                                       user_id: user.id
                                     })
    end

    it 'raises error if belongs to association is given a non-existant identifier' do
      params = { name: 'token', user: 'nonexistantstring' }

      expect { Token.association_name_to_id_convert(params) }
        .to raise_error Exceptions::UnprocessableEntity, %r{No lookup value found}
    end

    it 'converts non-user belongs to association by name' do
      organization = create(:organization)
      params       = { email: 'email@example.org', organization: organization.name }

      converted_params = User.association_name_to_id_convert(params)

      expect(converted_params)
        .to eq({
                 email:           'email@example.org',
                 organization_id: organization.id
               })
    end

    it 'overrides belongs to association if both name and ID are given' do
      organization = create(:organization)
      params       = { email: 'email@example.org', organization: organization.name, organization_id: 123 }

      converted_params = User.association_name_to_id_convert(params)

      expect(converted_params).to eq(params)
    end

    it 'raises error if ID is given as belongs to identifier' do
      organization = create(:organization)
      params       = { email: 'email@example.org', organization: organization.id }

      expect { User.association_name_to_id_convert(params) }
        .to raise_error Exceptions::UnprocessableEntity, %r{No lookup value found}
    end
  end
end
