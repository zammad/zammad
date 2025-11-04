# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'User > Last Admin Check', type: :model do
  before do
    User.with_permissions(['admin', 'admin.user']).destroy_all
  end

  context 'when the admin role got renamed' do
    before do
      Role.find_by(name: 'Admin')&.update(name: 'Zammad Administrator')
    end

    context 'when no admin users exist' do
      it 'returns false' do
        expect(User.admin_user_exists?).to be false
      end
    end

    context 'when an admin user exists' do
      before do
        create(:user, roles: Role.where(name: 'Zammad Administrator'))
      end

      it 'returns true' do
        expect(User.admin_user_exists?).to be true
      end
    end
  end
end
