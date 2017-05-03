require 'rails_helper'
require 'import/ldap/user'

RSpec::Matchers.define_negated_matcher :not_change, :change

RSpec.describe Import::Ldap::User do

  let(:uid) { 'exampleuid' }

  let(:ldap_config) do
    {
      user_uid:        'uid',
      user_attributes: {
        'uid'   => 'login',
        'email' => 'email',
      }
    }
  end

  let(:user_entry) do
    user_entry = build(:ldap_entry)

    user_entry['uid']   = [uid]
    user_entry['email'] = ['example@example.com']

    user_entry
  end

  let(:user_roles) do
    {
      user_entry.dn => [1]
    }
  end

  let(:signup_role_ids) do
    Role.signup_role_ids.sort
  end

  context 'create' do

    it 'creates users from LDAP Entry' do
      expect do
        described_class.new(user_entry, ldap_config, user_roles, signup_role_ids)
      end.to change {
        User.count
      }.by(1).and change {
        ExternalSync.count
      }.by(1)
    end

    it "doesn't contact avatar webservice" do
      # sadly we can't ensure that there are no
      # outgoing HTTP calls with WebMock
      expect(Avatar).not_to receive(:auto_detection)
      described_class.new(user_entry, ldap_config, user_roles, signup_role_ids)
    end

    it 'creates an HTTP Log entry' do
      expect do
        described_class.new(user_entry, ldap_config, user_roles, signup_role_ids)
      end.to change {
        HttpLog.count
      }.by(1)

      expect(HttpLog.last.status).to eq('success')
    end

    it 'uses mapped roles from group role' do
      described_class.new(user_entry, ldap_config, user_roles, signup_role_ids)
      expect(User.last.role_ids).not_to eq(signup_role_ids)
    end

    it 'uses Signup roles if no group role mapping was found' do

      # update old
      user_roles[ user_entry.dn ] = [1, 2]

      # change dn so no mapping will match
      user_entry['dn'] = ['some_unmapped_dn']

      described_class.new(user_entry, ldap_config, user_roles, signup_role_ids)
      expect(User.last.role_ids).to eq(signup_role_ids)
    end

    it 'skips User entries without attributes' do

      skip_entry = build(:ldap_entry)

      skip_entry['uid'] = [uid]

      expect do
        described_class.new(skip_entry, ldap_config, user_roles, signup_role_ids)
      end.to not_change {
        User.count
      }
    end

    it 'logs failures to HTTP Log' do
      expect_any_instance_of(User).to receive(:save).and_raise('SOME ERROR')
      described_class.new(user_entry, ldap_config, user_roles, signup_role_ids)

      expect(HttpLog.last.status).to eq('failed')
    end
  end

  context 'update' do

    before(:each) do
      user = create(:user,
                    login:    uid,
                    role_ids: [
                      Role.find_by(name: 'Agent').id,
                      Role.find_by(name: 'Admin').id
                    ])

      ExternalSync.create(
        source:    'Ldap::User',
        source_id: uid,
        object:    'User',
        o_id:      user.id
      )
    end

    it 'updates users from LDAP Entry' do
      expect do
        described_class.new(user_entry, ldap_config, user_roles, signup_role_ids)
      end.to not_change {
        User.count
      }.and not_change {
        ExternalSync.count
      }
    end

    it "doesn't contact avatar webservice" do
      # sadly we can't ensure that there are no
      # outgoing HTTP calls with WebMock
      expect(Avatar).not_to receive(:auto_detection)
      described_class.new(user_entry, ldap_config, user_roles, signup_role_ids)
    end

    it "doesn't change roles if no role mapping is configured" do
      expect do
        described_class.new(user_entry, ldap_config, {}, signup_role_ids)
      end.to not_change {
        User.last.role_ids
      }
    end

    it 'creates an HTTP Log entry' do
      expect do
        described_class.new(user_entry, ldap_config, user_roles, signup_role_ids)
      end.to change {
        HttpLog.count
      }.by(1)

      expect(HttpLog.last.status).to eq('success')
    end

    it 'finds existing Users without ExternalSync entries' do
      ExternalSync.find_by(
        source:    'Ldap::User',
        source_id: uid,
        object:    'User',
      ).destroy

      expect do
        described_class.new(user_entry, ldap_config, user_roles, signup_role_ids)
      end.to not_change {
        User.count
      }.and change {
        ExternalSync.count
      }.by(1)
    end

    it 'logs failures to HTTP Log' do
      expect_any_instance_of(User).to receive(:save).and_raise('SOME ERROR')
      described_class.new(user_entry, ldap_config, user_roles, signup_role_ids)

      expect(HttpLog.last.status).to eq('failed')
    end
  end
end
