# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe AutoWizard do
  describe '.enabled?' do
    context 'with no "auto_wizard.json" file in project root' do
      before { FileUtils.rm(Rails.root.join('auto_wizard.json'), force: true) }

      it 'returns false' do
        expect(described_class.enabled?).to be(false)
      end
    end

    context 'with "auto_wizard.json" file in project root' do
      around do |example|
        FileUtils.touch(Rails.root.join('auto_wizard.json'))
        example.run
        FileUtils.rm(Rails.root.join('auto_wizard.json'))
      end

      it 'returns true' do
        expect(described_class.enabled?).to be(true)
      end
    end
  end

  describe '.setup' do
    around do |example|
      File.write(Rails.root.join('auto_wizard.json'), seed_data.to_json)
      example.run
      FileUtils.rm(Rails.root.join('auto_wizard.json'), force: true)
    end

    let(:seed_data) { {} }

    it 'removes "auto_wizard.json" file when complete' do
      expect { described_class.setup }
        .to change { File.exist?(Rails.root.join('auto_wizard.json')) }.to(false)
    end

    context 'when "auto_wizard.json" contains a set of User attributes and associations (Role names)' do
      let(:seed_data) do
        {
          Users: [
            {
              login:     'master_unit_test01@example.com',
              firstname: 'Test Master',
              lastname:  'Agent',
              email:     'master_unit_test01@example.com',
              password:  'test',
              roles:     ['Agent']
            }
          ]
        }
      end

      it 'creates a user with those attributes and roles' do
        expect { described_class.setup }
          .to change(User, :count).by(1)
          .and change { User.last.roles }.to(Role.where(name: 'Agent'))
          .and change { User.last.login }.to('master_unit_test01@example.com')
          .and change { User.last.firstname }.to('Test Master')
          .and change { User.last.lastname }.to('Agent')
          .and change { User.last.email }.to('master_unit_test01@example.com')
          .and change { User.authenticate(User.last.email, 'test') }.from(nil)
      end
    end

    context 'when "auto_wizard.json" contains a set of User attributes without associations' do
      let(:seed_data) do
        {
          Users: [
            {
              login:     'master_unit_test01@example.com',
              firstname: 'Test Master',
              lastname:  'Agent',
              email:     'master_unit_test01@example.com',
              password:  'test'
            }
          ]
        }
      end

      it 'creates a user with those attributes and Admin + Agent roles' do
        expect { described_class.setup }
          .to change(User, :count).by(1)
          .and change { User.last.roles }.to(Role.where(name: %w[Admin Agent]))
          .and change { User.last.login }.to('master_unit_test01@example.com')
          .and change { User.last.firstname }.to('Test Master')
          .and change { User.last.lastname }.to('Agent')
          .and change { User.last.email }.to('master_unit_test01@example.com')
          .and change { User.authenticate(User.last.email, 'test') }.from(nil)
      end
    end

    context 'when "auto_wizard.json" contains a set of Group attributes and associations (User emails, Signature name, & EmailAddress id)' do
      let(:seed_data) do
        {
          Groups: [
            {
              name:             'some group1',
              note:             'Lorem ipsum dolor',
              users:            [group_agent.email],
              signature:        group_signature.name,
              email_address_id: group_email.id,
            }
          ]
        }
      end

      let(:group_agent) { create(:agent) }
      let(:group_signature) { create(:signature) }
      let(:group_email) { create(:email_address) }

      it 'creates a group with those attributes and associations' do
        expect { described_class.setup }
          .to change(Group, :count).by(1)
          .and change { Group.last.name }.to('some group1')
          .and change { Group.last.note }.to('Lorem ipsum dolor')
          .and change { Group.last.users }.to([group_agent])
          .and change { Group.last.signature }.to(group_signature)
      end
    end

    context 'when "auto_wizard.json" contains a set of EmailAddress attributes' do
      let(:seed_data) do
        {
          EmailAddresses: [
            {
              channel_id: channel.id,
              realname:   'John Doe',
              email:      'johndoe@example.com',
            }
          ],
        }
      end

      let(:channel) { create(:email_channel) }

      it 'creates an email address with the given attributes' do
        expect { described_class.setup }
          .to change(EmailAddress, :count)
          .and change { EmailAddress.last&.realname }.to('John Doe')
          .and change { EmailAddress.last&.email }.to('johndoe@example.com')
          .and change { EmailAddress.last&.channel }.to(channel)
      end
    end

    context 'when "auto_wizard.json" contains a set of EmailAddress attributes, including an existing ID' do
      let(:seed_data) do
        {
          EmailAddresses: [
            {
              id:         email_address.id,
              channel_id: new_channel.id,
              realname:   'John Doe',
              email:      'johndoe@example.com',
            }
          ],
        }
      end

      let(:email_address) { create(:email_address) }
      let(:new_channel) { create(:email_channel) }

      it 'updates the specified email address with the given attributes' do
        expect { described_class.setup }
          .to not_change(EmailAddress, :count)
          .and change { email_address.reload.realname }.to('John Doe')
          .and change { email_address.reload.email }.to('johndoe@example.com')
          .and change { email_address.reload.channel }.to(new_channel)
      end
    end

    context 'when "auto_wizard.json" contains a set of Channel attributes' do
      let(:seed_data) do
        {
          Channels: [
            {
              id:          100,
              area:        'Email::Account',
              group:       'Users',
              options:     {
                inbound:  {
                  adapter: 'imap',
                  options: {
                    host:     'mx1.example.com',
                    user:     'not_existing',
                    password: 'some_pass',
                    ssl:      true
                  }
                },
                outbound: {
                  adapter: 'sendmail'
                }
              },
              preferences: {
                online_service_disable: true,
              },
              active:      true
            }
          ],
        }
      end

      it 'creates a new channel with the given attributes' do
        expect { described_class.setup }
          .to change(Channel, :count)
          .and change { Channel.last&.group }.to(Group.find_by(name: 'Users'))
          .and change { Channel.last&.area }.to('Email::Account')
      end
    end

    context 'when "auto_wizard.json" contains a set of Channel attributes, including an existing ID' do
      let(:seed_data) do
        {
          Channels: [
            {
              id:          channel.id,
              area:        'Email::Account',
              group:       new_group.name,
              options:     {
                inbound:  {
                  adapter: 'imap',
                  options: {
                    host:     'mx1.example.com',
                    user:     'not_existing',
                    password: 'some_pass',
                    ssl:      true
                  }
                },
                outbound: {
                  adapter: 'sendmail'
                }
              },
              preferences: {
                online_service_disable: true,
              },
              active:      true
            }
          ],
        }
      end

      let(:channel) { create(:twitter_channel) }
      let(:new_group) { create(:group) }

      it 'updates the specified channel with the given attributes' do
        expect { described_class.setup }
          .to not_change(Channel, :count)
          .and change { channel.reload.group }.to(new_group)
          .and change { channel.reload.area }.to('Email::Account')
      end
    end

    context 'when "auto_wizard.json" contains a set of existing permission names and active-statuses' do
      let(:seed_data) do
        {
          Permissions: [
            {
              name:   'admin.session',
              active: false,
            },
          ],
        }
      end

      it 'sets the specified permissions to the given active-statuses' do
        expect { described_class.setup }
          .to not_change(Permission, :count)
          .and change { Permission.find_by(name: 'admin.session').active }.to(false)
      end
    end

    context 'when "auto_wizard.json" contains a set of new permission names and active-statuses' do
      let(:seed_data) do
        {
          Permissions: [
            {
              name:   'admin.session.new',
              active: false,
            },
          ],
        }
      end

      it 'creates a new permission with the given active-status' do
        expect { described_class.setup }
          .to change(Permission, :count).by(1)
          .and change { Permission.last.name }.to('admin.session.new')
          .and change { Permission.last.active }.to(false)
      end
    end

    context 'when "auto_wizard.json" contains sets of existing Setting names and values' do
      let(:seed_data) do
        {
          Settings: [
            {
              name:  'developer_mode',
              value: true
            },
            {
              name:  'product_name',
              value: 'Zammad UnitTest01 System'
            }
          ]
        }
      end

      it 'sets the specified settings to the given values' do
        expect { described_class.setup }
          .to change { Setting.get('developer_mode') }.to(true)
          .and change { Setting.get('product_name') }.to('Zammad UnitTest01 System')
      end
    end

    context 'when "auto_wizard.json" contains a TextModule locale' do
      let(:seed_data) do
        {
          TextModuleLocale: {
            Locale: 'de-de'
          }
        }
      end

      it 'creates a full set of text modules for the specified locale' do
        expect { described_class.setup }
          .to change(TextModule, :count)
      end
    end

    context 'when "auto_wizard.json" contains a Calendar IP' do
      let(:seed_data) do
        {
          CalendarSetup: {
            Ip: '195.65.29.254',
          },
        }
      end

      it 'updates the existing calendar with the specified IP' do
        expect { described_class.setup }
          .to not_change(Calendar, :count)
          .and change { Calendar.last.name }.to('Switzerland')
          .and change { Calendar.last.timezone }.to('Europe/Zurich')
      end
    end

  end
end
