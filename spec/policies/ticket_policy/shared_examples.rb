# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'for agent user' do |access_type|
  let(:member_groups)   { create_list(:group, 2) }
  let(:nonmember_group) { create(:group) }

  before do
    create(:ticket, group: member_groups.first)
    create(:ticket, group: member_groups.second)
    create(:ticket, group: nonmember_group)
  end

  shared_examples 'shown' do
    it 'returns its groups’ tickets' do
      expect(scope.resolve).to match_array(Ticket.where(group: member_groups))
    end
  end

  shared_examples 'hidden' do
    it 'does not return its groups’ tickets' do
      expect(scope.resolve).to be_empty
    end
  end

  context 'with direct access via User#groups' do
    let(:user) { create(:agent, groups: member_groups) }

    context 'when checking for "full" access' do
      # this is already true by default, but it doesn't hurt to be explicit
      before { user.user_groups.each { |ug| ug.update_columns(access: 'full') } }

      include_examples 'shown'
    end

    context 'when limited to "read" access' do
      before { user.user_groups.each { |ug| ug.update_columns(access: 'read') } }

      include_examples access_type == 'read' ? 'shown' : 'hidden'
    end

    context 'when limited to "overview" access' do
      before { user.user_groups.each { |ug| ug.update_columns(access: 'overview') } }

      include_examples access_type == 'overview' ? 'shown' : 'hidden'
    end
  end

  context 'without any role permission' do

    let(:role_without_rights) { create(:role) }
    let(:user)                { create(:agent, groups: member_groups, role_ids: [ role_without_rights.id ]) }

    context 'when checking for "full" access' do
      # this is already true by default, but it doesn't hurt to be explicit
      before { user.user_groups.each { |ug| ug.update_columns(access: 'full') } }

      include_examples 'hidden'
    end

    context 'when limited to "read" access' do
      before { user.user_groups.each { |ug| ug.update_columns(access: 'read') } }

      include_examples 'hidden'
    end

    context 'when limited to "overview" access' do
      before { user.user_groups.each { |ug| ug.update_columns(access: 'overview') } }

      include_examples 'hidden'
    end
  end

  context 'with report permission' do

    let(:report_role) { create(:role).tap { |role| role.permission_grant('report') } }
    let(:user) { create(:agent, groups: member_groups, role_ids: [ report_role.id ]) }

    context 'when checking for "full" access' do
      # this is already true by default, but it doesn't hurt to be explicit
      before { user.user_groups.each { |ug| ug.update_columns(access: 'full') } }

      it 'grants access to all tickets' do
        expect(scope.resolve).to match_array(Ticket.all)
      end
    end

    context 'when limited to "read" access' do
      before { user.user_groups.each { |ug| ug.update_columns(access: 'read') } }

      it 'grants access to all tickets' do
        expect(scope.resolve).to match_array(Ticket.all)
      end
    end

    context 'when limited to "overview" access' do
      before { user.user_groups.each { |ug| ug.update_columns(access: 'overview') } }

      it 'grants access to all tickets' do
        expect(scope.resolve).to match_array(Ticket.all)
      end
    end
  end

  context 'with indirect access via Role#groups' do
    let(:user) { create(:agent).tap { |u| u.roles << role } }
    let(:role) { create(:role, groups: member_groups) }

    context 'when checking for "full" access' do
      # this is already true by default, but it doesn't hurt to be explicit
      before { role.role_groups.each { |rg| rg.update_columns(access: 'full') } }

      include_examples 'shown'
    end

    context 'when limited to "read" access' do
      before { role.role_groups.each { |rg| rg.update_columns(access: 'read') } }

      include_examples access_type == 'read' ? 'shown' : 'hidden'
    end

    context 'when limited to "overview" access' do
      before { role.role_groups.each { |rg| rg.update_columns(access: 'overview') } }

      include_examples access_type == 'overview' ? 'shown' : 'hidden'
    end
  end

  context 'when checking access via customer organization but no customer permissions' do
    let(:user) { create(:agent, organization: organization) }

    let(:teammate) { create(:agent, organization: organization) }

    before do
      create_list(:ticket, 2, customer: user)
      create_list(:ticket, 2, customer: teammate)
    end

    context 'with no #organization' do
      let(:organization) { nil }

      it 'returns no tickets' do
        expect(scope.resolve).to be_empty
      end
    end

    context 'with a non-shared #organization' do
      let(:organization) { create(:organization, shared: false) }

      it 'returns no tickets' do
        expect(scope.resolve).to be_empty
      end
    end

    context 'with a shared #organization (default)' do
      let(:organization) { create(:organization, shared: true) }

      it 'returns no tickets' do
        expect(scope.resolve).to be_empty
      end
    end
  end
end

RSpec.shared_examples 'for agent user with predefined but impossible context' do
  let(:member_groups)   { create_list(:group, 2) }
  let(:nonmember_group) { create(:group) }
  let(:user)            { create(:agent, groups: member_groups) }

  before do
    create(:ticket, group: member_groups.first)
    create(:ticket, group: member_groups.second)
    create(:ticket, group: nonmember_group)
  end

  it 'does not find tickets because of restrictive predefined scope' do
    expect(scope.resolve).to match_array(Ticket.where(id: -1))
  end
end

RSpec.shared_examples 'for customer user' do
  let(:user) { create(:customer, organization: organization) }
  let!(:user_tickets) { create_list(:ticket, 2, customer: user) }

  let(:teammate) { create(:customer, organization: organization) }
  let!(:teammate_tickets) { create_list(:ticket, 2, customer: teammate) }

  context 'with no #organization' do
    let(:organization) { nil }

    it 'returns only the customer’s tickets' do
      expect(scope.resolve).to match_array(user_tickets)
    end
  end

  context 'with a non-shared #organization' do
    let(:organization) { create(:organization, shared: false) }

    it 'returns only the customer’s tickets' do
      expect(scope.resolve).to match_array(user_tickets)
    end
  end

  context 'with a shared #organization (default)' do
    let(:organization) { create(:organization, shared: true) }

    it 'returns only the customer’s or organization’s tickets' do
      expect(scope.resolve).to match_array(user_tickets | teammate_tickets)
    end
  end

  context 'with a multi #organization (shared false)' do
    let(:user)         { create(:customer, organization: organization, organizations: [secondary_organization]) }
    let(:organization) { create(:organization, shared: true) }

    let(:secondary_organization) { create(:organization, shared: false) }
    let(:secondarymate)         { create(:customer, organization: secondary_organization) }
    let(:secondarymate_tickets) { create_list(:ticket, 2, customer: secondarymate) }

    before do
      secondarymate_tickets
    end

    it 'returns only the customer’s or organization’s tickets' do
      expect(scope.resolve).to match_array(user_tickets | teammate_tickets)
    end
  end

  context 'with a multi #organization (shared true)' do
    let(:user) { create(:customer, organization: organization, organizations: [secondary_organization]) }
    let(:organization) { create(:organization, shared: false) }

    let(:secondary_organization) { create(:organization, shared: true) }
    let(:secondarymate)         { create(:customer, organization: secondary_organization) }
    let(:secondarymate_tickets) { create_list(:ticket, 2, customer: secondarymate) }

    before do
      secondarymate_tickets
    end

    it 'returns only the customer’s or organization’s tickets' do
      expect(scope.resolve).to match_array(user_tickets | secondarymate_tickets)
    end
  end
end
