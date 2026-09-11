# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe UserInfo::Assets do
  describe '.level_for' do
    it 'returns nil without a user' do
      expect(described_class.level_for(nil)).to be_nil
    end

    it 'returns the customer level for a customer' do
      expect(described_class.level_for(create(:customer))).to eq(described_class::LEVEL_CUSTOMER)
    end

    it 'returns the agent level for an agent' do
      expect(described_class.level_for(create(:agent))).to eq(described_class::LEVEL_AGENT)
    end

    it 'returns the admin level for an admin' do
      expect(described_class.level_for(create(:admin))).to eq(described_class::LEVEL_ADMIN)
    end

    # The admin level wins over the agent level whichever way round the permissions come out of
    #   the database, so drive the order directly instead of hoping a factory produces it.
    context 'when a user is both an agent and an admin' do
      let(:user) { instance_double(User, blank?: false, permissions_with_child_names: permissions) }

      context 'with the agent permission first' do
        let(:permissions) { %w[ticket.agent admin.group] }

        it 'returns the admin level' do
          expect(described_class.level_for(user)).to eq(described_class::LEVEL_ADMIN)
        end
      end

      context 'with the admin permission first' do
        let(:permissions) { %w[admin.group ticket.agent] }

        it 'returns the admin level' do
          expect(described_class.level_for(user)).to eq(described_class::LEVEL_ADMIN)
        end
      end
    end
  end

  describe '.levels_for' do
    it 'returns an empty hash without ids' do
      expect(described_class.levels_for([])).to eq({})
    end

    # The resolver groups by role set instead of asking per user, so it has to keep agreeing
    #   with the per-user answer for every shape of user - an inactive role, an inactive user,
    #   a parent permission and no roles at all included.
    context 'with every shape of user' do
      let(:parent_admin_role) { create(:role, permissions: [Permission.find_by(name: 'admin')]) }
      let(:inactive_role)     { create(:role, active: false, permissions: [Permission.find_by(name: 'admin.group')]) }

      let(:users) do
        [
          create(:customer),
          create(:customer),
          create(:agent),
          create(:admin),
          create(:agent_and_customer),
          create(:user, roles: [parent_admin_role]),
          create(:user, roles: [Role.find_by(name: 'Customer'), inactive_role]),
          create(:admin, active: false),
          create(:user, roles: []),
        ]
      end

      it 'agrees with .level_for for each of them' do
        levels = described_class.levels_for(users.map(&:id))

        expect(levels).to eq(users.index_by(&:id).transform_values { |user| described_class.level_for(user) })
      end
    end

    it 'omits ids of users that do not exist' do
      user = create(:agent)

      expect(described_class.levels_for([user.id, 99_999_999])).to eq(user.id => described_class::LEVEL_AGENT)
    end

    it 'gives a user without any role the customer level' do
      user = create(:user, roles: [])

      expect(described_class.levels_for([user.id])).to eq(user.id => described_class::LEVEL_CUSTOMER)
    end

    # The point of the resolver: what it costs must not grow with the number of users.
    it 'resolves one level per role set rather than one per user' do
      users = create_list(:customer, 5) + create_list(:agent, 5)

      allow(described_class).to receive(:level_for).and_call_original

      described_class.levels_for(users.map(&:id))

      expect(described_class).to have_received(:level_for).twice
    end
  end

  describe '#initialize' do
    it 'derives the level from the given user' do
      user = create(:agent)

      expect(described_class.new(user.id)).to have_attributes(user: user, level: described_class::LEVEL_AGENT)
    end

    it 'takes an explicit level without a user' do
      expect(described_class.new(nil, level: described_class::LEVEL_CUSTOMER))
        .to have_attributes(user: nil, current_user_id: nil, level: described_class::LEVEL_CUSTOMER)
    end
  end

  describe '#check_level?' do
    context 'without a user' do
      subject(:assets) { described_class.new(nil) }

      # A cleared or never established context must not unlock agent or admin level data, that
      # is what made a lost request context leak unredacted assets to customers.
      it 'is not privileged', :aggregate_failures do
        expect(assets).not_to be_agent
        expect(assets).not_to be_admin
        expect(assets).not_to be_customer
      end

      it 'is privileged in a system context', :aggregate_failures do
        UserInfo.with_system_context do
          expect(assets).to be_agent
          expect(assets).to be_admin
        end
      end
    end

    # A broadcast knows the audience it renders for, but has no recipient to look a user up from.
    context 'with an explicit level and no user' do
      subject(:assets) { described_class.new(nil, level: UserInfo::Assets::LEVEL_CUSTOMER) }

      it 'answers at that level', :aggregate_failures do
        expect(assets).to be_customer
        expect(assets).not_to be_agent
        expect(assets).not_to be_admin
      end

      # Otherwise a job, which always runs in a system context, would render everyone the
      # unredacted payload despite having said who it is rendering for.
      it 'is not elevated by a system context' do
        UserInfo.with_system_context do
          expect(assets).not_to be_agent
        end
      end
    end

    context 'with a customer' do
      subject(:assets) { described_class.new(create(:customer).id) }

      it 'is customer level only', :aggregate_failures do
        expect(assets).to be_customer
        expect(assets).not_to be_agent
        expect(assets).not_to be_admin
      end

      it 'is not elevated by a system context' do
        UserInfo.with_system_context do
          expect(assets).not_to be_agent
        end
      end
    end

    context 'with an agent' do
      subject(:assets) { described_class.new(create(:agent).id) }

      it 'is agent level', :aggregate_failures do
        expect(assets).to be_agent
        expect(assets).not_to be_admin
      end
    end

    context 'with an admin' do
      subject(:assets) { described_class.new(create(:admin).id) }

      it 'is admin level' do
        expect(assets).to be_admin
      end
    end
  end
end
