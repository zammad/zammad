# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe HttpLogPolicy::Scope, :aggregate_failures do
  subject(:scope) { described_class.new(user, original_collection) }

  let(:original_collection) { HttpLog }

  let(:github_log) { create(:http_log, facility: 'GitHub') }
  let(:webhook_log) { create(:http_log, facility: 'webhook') }

  before do
    HttpLog.destroy_all
    github_log && webhook_log
  end

  describe '#resolve' do
    context 'with admin users' do
      let(:user) { create(:admin) }

      it 'returns all logs' do
        expect(scope.resolve).to contain_exactly(github_log, webhook_log)
      end

      it 'returns all logs when facility is given' do
        expect(scope.resolve(facility: 'GitHub')).to contain_exactly(github_log)
        expect(scope.resolve(facility: 'webhook')).to contain_exactly(webhook_log)
      end
    end

    context 'with admin with overview permission' do
      let(:admin_role) { create(:role, permission_names: ['admin.overview']) }
      let(:user)       { create(:user, roles: [admin_role]) }

      it 'returns no logs' do
        expect(scope.resolve).to be_empty
      end

      it 'returns no logs when facility is given' do
        expect(scope.resolve(facility: 'GitHub')).to be_empty
        expect(scope.resolve(facility: 'webhook')).to be_empty
      end
    end

    context 'with admin with facility specific permission' do
      let(:admin_role) { create(:role, permission_names: ['admin.integration']) }
      let(:user) { create(:user, roles: [admin_role]) }

      it 'returns only permitted logs' do
        expect(scope.resolve).to contain_exactly(github_log)
      end

      it 'returns only permitted logs when facility is given' do
        expect(scope.resolve(facility: 'GitHub')).to contain_exactly(github_log)
        expect(scope.resolve(facility: 'webhook')).to be_empty
      end
    end
  end

  context 'with agent users' do
    let(:user) { create(:agent) }

    it 'returns no logs' do
      expect(scope.resolve).to be_empty
    end
  end

  context 'with customer users' do
    let(:user) { create(:customer) }

    it 'returns no logs' do
      expect(scope.resolve).to be_empty
    end
  end
end
