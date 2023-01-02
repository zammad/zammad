# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Auth do
  let(:password) { 'zammad' }
  let(:user)     { create(:user, password: password) }
  let(:instance) { described_class.new(user.login, password) }

  before do
    stub_const('Auth::BRUTE_FORCE_SLEEP', 0)
  end

  describe '.valid?' do
    it 'responds to valid?' do
      expect(instance).to respond_to(:valid?)
    end

    context 'with an internal user' do
      context 'with valid credentials' do
        it 'check for valid credentials' do
          expect(instance.valid?).to be true
        end

        it 'check for not increased failed login count' do
          expect { instance.valid? }.not_to change { user.reload.login_failed }
        end

        context 'when not case-sensitive' do
          let(:instance) { described_class.new(user.login.upcase, password) }

          it 'returns true' do
            expect(instance.valid?).to be true
          end
        end

        context 'when email is used' do
          let(:instance) { described_class.new(user.email, password) }

          it 'check for valid credentials' do
            expect(instance.valid?).to be true
          end
        end

        context 'when previous login was' do
          context 'when never logged in' do
            it 'updates #last_login and #updated_at' do
              expect { instance.valid? }.to change { user.reload.last_login }.and change { user.reload.updated_at }
            end
          end

          context 'when less than 10 minutes ago' do
            before do
              instance.valid?
              travel 9.minutes
            end

            it 'does not update #last_login and #updated_at' do
              expect { instance.valid? }.to not_change { user.reload.last_login }.and not_change { user.reload.updated_at }
            end
          end

          context 'when more than 10 minutes ago' do
            before do
              instance.valid?
              travel 11.minutes
            end

            it 'updates #last_login and #updated_at' do
              expect { instance.valid? }.to change { user.reload.last_login }.and change { user.reload.updated_at }
            end
          end
        end
      end

      context 'with valid user and invalid password' do
        let(:instance) { described_class.new(user.login, 'wrong') }

        it 'check for invalid credentials' do
          expect(instance.valid?).to be false
        end

        it 'check for increased failed login count' do
          expect { instance.valid? }.to change { user.reload.login_failed }.from(0).to(1)
        end

        it 'failed login avoids brute force attack' do
          allow(instance).to receive(:sleep)
          instance.valid?
          # sleep receives the stubbed value.
          expect(instance).to have_received(:sleep).with(0)
        end
      end

      context 'with inactive user login' do
        let(:user) { create(:user, active: false) }

        it 'returns false' do
          expect(instance.valid?).to be false
        end
      end

      context 'with non-existent user login' do
        let(:instance) { described_class.new('not_existing', password) }

        it 'returns false' do
          expect(instance.valid?).to be false
        end
      end

      context 'with empty user login' do
        let(:instance) { described_class.new('', password) }

        it 'returns false' do
          expect(instance.valid?).to be false
        end
      end

      context 'when password is empty' do
        before do
          # Remove adapter from auth developer setting, to avoid execution for this test case, because of special empty
          # password handling in adapter.
          Setting.set('auth_developer', {})
        end

        context 'with empty password string' do
          let(:password) { '' }

          it 'returns false' do
            expect(instance.valid?).to be false
          end
        end

        shared_examples 'check empty password' do
          context 'when password is an empty string' do
            let(:password) { '' }

            it 'returns false' do
              expect(instance.valid?).to be false
            end
          end

          context 'when password is nil' do
            let(:password) { nil }

            it 'returns false' do
              expect(instance.valid?).to be false
            end
          end
        end

        context 'with empty password string when the stored password is an empty string' do
          before { user.update_column(:password, '') }

          include_examples 'check empty password'
        end

        context 'with empty password string when the stored hash represents an empty string' do
          before { user.update(password: PasswordHash.crypt('')) }

          include_examples 'check empty password'
        end
      end
    end

    context 'with a ldap user' do
      let(:password_ldap) { 'zammad_ldap' }
      let(:ldap_user)     { instance_double(Ldap::User) }

      before do
        Setting.set('ldap_integration', true)

        allow(Ldap::User).to receive(:new).with(any_args).and_return(ldap_user)
      end

      shared_examples 'check empty password' do
        before do
          # Remove adapter from auth developer setting, to avoid execution for this test case, because of special empty
          # password handling in adapter.
          Setting.set('auth_developer', {})
        end

        context 'with empty password string' do
          let(:password) { '' }

          it 'returns false' do
            expect(instance.valid?).to be false
          end
        end

        context 'when password is nil' do
          let(:password) { nil }

          it 'returns false' do
            expect(instance.valid?).to be false
          end
        end
      end

      context 'with a ldap user without internal password' do
        let(:ldap_source) { create(:ldap_source) }
        let(:user)     { create(:user, source: "Ldap::#{ldap_source.id}") }
        let(:password) { password_ldap }

        context 'with valid credentials' do
          before do
            allow(ldap_user).to receive(:valid?).with(any_args).and_return(true)
          end

          it 'returns true' do
            expect(instance.valid?).to be true
          end
        end

        context 'with invalid credentials' do
          let(:password) { 'wrong' }

          before do
            allow(ldap_user).to receive(:valid?).with(any_args).and_return(false)
          end

          it 'returns false' do
            expect(instance.valid?).to be false
          end

          it 'check for not increased failed login count' do
            expect { instance.valid? }.not_to change { user.reload.login_failed }
          end
        end

        include_examples 'check empty password'
      end

      context 'with a ldap user which also has a internal password' do
        let(:user)     { create(:user, source: 'Ldap', password: password) }
        let(:password) { password_ldap }

        context 'with valid ldap credentials' do
          before do
            allow(ldap_user).to receive(:valid?).with(any_args).and_return(true)
          end

          it 'returns true' do
            expect(instance.valid?).to be true
          end
        end

        context 'with invalid ldap credentials' do
          let(:instance) { described_class.new(user.login, 'wrong') }

          before do
            allow(ldap_user).to receive(:valid?).with(any_args).and_return(false)
          end

          it 'returns false' do
            expect(instance.valid?).to be false
          end

          it 'check for not increased failed login count' do
            expect { instance.valid? }.to change { user.reload.login_failed }.from(0).to(1)
          end
        end

        context 'with valid internal credentials' do
          before do
            allow(ldap_user).to receive(:valid?).with(any_args).and_return(false)
          end

          it 'returns true' do
            expect(instance.valid?).to be true
          end
        end

        include_examples 'check empty password'
      end
    end
  end
end
