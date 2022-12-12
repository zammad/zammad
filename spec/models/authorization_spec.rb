# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe Authorization, type: :model do
  describe 'User assets' do
    subject(:authorization) { create(:twitter_authorization) }

    it 'does update assets after new authorizations created' do
      authorization.user.assets({})
      create(:twitter_authorization, provider: 'twitter2', user: authorization.user)
      assets = authorization.user.reload.assets({})
      expect(assets[:User][authorization.user.id]['accounts'].keys.count).to eq(2)
    end
  end

  describe 'Account linking notification', sends_notification_emails: true do
    subject(:authorization) { create(:authorization, user: agent, provider: 'github') }

    let(:agent) { create(:agent) }

    shared_examples 'sending out email notification' do
      it 'sends out an email notification' do
        check_notification do
          authorization

          sent(
            template: 'user_auth_provider',
            user:     authorization.user,
            objects:  hash_including({ user: authorization.user, provider: authorization.provider })
          )
        end
      end
    end

    shared_examples 'not sending out email notification' do
      it 'does not send out an email notification' do
        check_notification do
          authorization

          not_sent(
            template: 'user_auth_provider',
            user:     authorization.user,
            objects:  hash_including({ user: authorization.user, provider: authorization.provider })
          )
        end
      end
    end

    context 'with setting turned on' do
      before do
        Setting.set('auth_third_party_linking_notification', true)
      end

      context 'when linking with an existing account' do
        it_behaves_like 'sending out email notification'

        context 'when user has no email address' do
          let(:agent) { create(:agent, email: '') }

          it_behaves_like 'not sending out email notification'
        end
      end

      context 'when creating a new account' do
        let(:agent) { create(:agent, source: 'github') }

        it_behaves_like 'not sending out email notification'
      end
    end

    context 'with setting turned off' do
      before do
        Setting.set('auth_third_party_linking_notification', false)
      end

      it_behaves_like 'not sending out email notification'
    end
  end
end
