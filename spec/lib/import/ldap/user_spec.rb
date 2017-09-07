require 'rails_helper'
require 'import/ldap/user'

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
      user_entry.dn => [
        Role.find_by(name: 'Admin').id,
        Role.find_by(name: 'Agent').id
      ]
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

    it 'logs failures to HTTP Log' do
      expect_any_instance_of(User).to receive(:save!).and_raise('SOME ERROR')
      described_class.new(user_entry, ldap_config, user_roles, signup_role_ids)

      expect(HttpLog.last.status).to eq('failed')
    end

    context 'role assignment' do

      it 'uses mapped roles from group role' do
        described_class.new(user_entry, ldap_config, user_roles, signup_role_ids)
        expect(User.last.role_ids).not_to eq(signup_role_ids)
      end

      context 'no mapping entry' do

        before(:each) do
          # create mapping that won't match
          # since dn will change below
          # this is needed since if 'user_roles'
          # gets called later it will get initialized
          # with the changed dn
          user_roles[ user_entry.dn ] = [
            Role.find_by(name: 'Admin').id,
            Role.find_by(name: 'Agent').id
          ]

          # change dn so no mapping will match
          user_entry['dn'] = ['some_unmapped_dn']
        end

        it 'uses signup roles by default' do
          described_class.new(user_entry, ldap_config, user_roles, signup_role_ids)
          expect(User.last.role_ids).to eq(signup_role_ids)
        end

        it 'uses signup roles if configured' do

          ldap_config[:unassigned_users] = 'sigup_roles'

          described_class.new(user_entry, ldap_config, user_roles, signup_role_ids)
          expect(User.last.role_ids).to eq(signup_role_ids)
        end

        it 'skips user if configured' do

          ldap_config[:unassigned_users] = 'skip_sync'

          instance = nil
          expect do
            instance = described_class.new(user_entry, ldap_config, user_roles, signup_role_ids)
          end.not_to change {
            User.count
          }
          expect(instance.action).to eq(:skipped)
        end
      end
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
      expect_any_instance_of(User).to receive(:save!).and_raise('SOME ERROR')
      described_class.new(user_entry, ldap_config, user_roles, signup_role_ids)

      expect(HttpLog.last.status).to eq('failed')
    end

    context 'no mapping entry' do

      before(:each) do
        # create mapping that won't match
        # since dn will change below
        # this is needed since if 'user_roles'
        # gets called later it will get initialized
        # with the changed dn
        user_roles[ user_entry.dn ] = [
          Role.find_by(name: 'Agent').id,
          Role.find_by(name: 'Admin').id
        ]

        # change dn so no mapping will match
        user_entry['dn'] = ['some_unmapped_dn']
      end

      it 'keeps local roles by default' do
        expect do
          described_class.new(user_entry, ldap_config, user_roles, signup_role_ids)
        end.not_to change {
          User.last.role_ids
        }
      end

      it 'skips user if configured' do

        ldap_config[:unassigned_users] = 'skip_sync'

        instance = nil
        expect do
          instance = described_class.new(user_entry, ldap_config, user_roles, signup_role_ids)
        end.not_to change {
          User.count
        }
        expect(instance.action).to eq(:skipped)
      end

      context 'signup roles configuration' do
        it 'keeps local roles' do

          ldap_config[:unassigned_users] = 'sigup_roles'
          expect do
            described_class.new(user_entry, ldap_config, user_roles, signup_role_ids)
          end.not_to change {
            User.last.role_ids
          }
        end

        it "doesn't detect false changes" do
          # make sure that the nothing has changed
          User.find_by(login: uid).update_attribute(:email, 'example@example.com')

          expect_any_instance_of(User).not_to receive(:save!)
          instance = described_class.new(user_entry, ldap_config, user_roles, signup_role_ids)
          expect(instance.action).to eq(:unchanged)
        end
      end
    end
  end

  context 'skipped' do

    it 'skips entries without login' do
      skip_entry = build(:ldap_entry)
      instance   = nil

      expect do
        instance = described_class.new(skip_entry, ldap_config, user_roles, signup_role_ids)
      end.to not_change {
        User.count
      }
      expect(instance.action).to eq(:skipped)
    end

    it 'skips entries without attributes' do
      skip_entry        = build(:ldap_entry)
      skip_entry['uid'] = [uid]
      instance          = nil

      expect do
        instance = described_class.new(skip_entry, ldap_config, user_roles, signup_role_ids)
      end.to not_change {
        User.count
      }
      expect(instance.action).to eq(:skipped)
    end

    it 'logs skips to HTTP Log' do
      skip_entry = build(:ldap_entry)
      described_class.new(skip_entry, ldap_config, user_roles, signup_role_ids)

      expect(HttpLog.last.status).to eq('success')
      expect(HttpLog.last.url).to start_with('skipped')
    end
  end
end
