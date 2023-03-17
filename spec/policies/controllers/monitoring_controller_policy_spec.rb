# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

describe Controllers::MonitoringControllerPolicy do
  let(:instance)     { described_class.new(user_context, record) }
  let(:record_class) { MonitoringController }
  let(:action_name)  { :sample }
  let(:params)       { { token: token } }
  let(:token)        { nil }
  let(:user_context) { UserContext.new(user) }
  let(:record) do
    rec             = record_class.new
    rec.action_name = action_name
    rec.params      = params

    rec
  end

  shared_examples 'token or permission' do
    let(:user) { create(:admin) }

    before do
      allow(instance).to receive(:token_or_permission?).and_return(token_or_permission)
    end

    context 'when token or permission' do
      let(:token_or_permission) { true }

      it 'permits action' do
        expect(instance).to permit_action(action_name)
      end
    end

    context 'when no token or permission' do
      let(:token_or_permission) { false }

      it 'forbids action' do
        expect(instance).to forbid_action(action_name)
      end
    end
  end

  shared_examples 'only permission' do
    let(:user) { create(:admin) }

    before do
      allow(instance).to receive(:permission_and_permission_active?).and_return(permission)
    end

    context 'when permission' do
      let(:permission) { true }

      it 'permits action' do
        expect(instance).to permit_action(action_name)
      end
    end

    context 'when no permission' do
      let(:permission) { false }

      it 'forbids action' do
        expect(instance).to forbid_action(action_name)
      end
    end
  end

  describe '#health_check?' do
    let(:action_name) { :health_check }

    include_examples 'token or permission'
  end

  describe '#status?' do
    let(:action_name) { :status }

    include_examples 'token or permission'
  end

  describe '#amount_check?' do
    let(:action_name) { :amount_check }

    include_examples 'token or permission'
  end

  describe '#token?' do
    let(:action_name) { :token }

    include_examples 'only permission'
  end

  describe '#restart_failed_jobs?' do
    let(:action_name) { :restart_failed_jobs }

    include_examples 'only permission'
  end

  describe '#token_or_permission' do
    context 'when not logged' do
      let(:user)  { nil }

      context 'when no token' do
        let(:token) { nil }

        it 'returns false' do
          expect(instance.send(:token_or_permission?)).to be_falsey
        end
      end

      context 'when token given' do
        let(:token) { Setting.get('monitoring_token') }

        it 'returns true' do
          expect(instance.send(:token_or_permission?)).to be_truthy
        end
      end
    end

    context 'when user does not have permission' do
      let(:user) { create(:agent) }

      it 'returns false' do
        expect(instance.send(:token_or_permission?)).to be_falsey
      end

      context 'when token given' do
        let(:token) { Setting.get('monitoring_token') }

        it 'returns false' do
          expect(instance.send(:token_or_permission?)).to be_falsey
        end
      end
    end

    context 'when user has permission' do
      let(:user)  { create(:admin) }

      it 'returns true' do
        expect(instance.send(:token_or_permission?)).to be_truthy
      end

      context 'when token given' do
        let(:token) { Setting.get('monitoring_token') }

        it 'returns true' do
          expect(instance.send(:token_or_permission?)).to be_truthy
        end
      end
    end
  end

  describe '#permission_and_permission_active?' do
    context 'when not logged in' do
      let(:user) { nil }

      it 'returns false' do
        expect(instance.send(:permission_and_permission_active?)).to be_falsey
      end
    end

    context 'when user does not have permission' do
      let(:user) { create(:agent) }

      it 'returns false' do
        expect(instance.send(:permission_and_permission_active?)).to be_falsey
      end
    end

    context 'when user has permission' do
      let(:user) { create(:admin) }

      it 'returns true' do
        expect(instance.send(:permission_and_permission_active?)).to be_truthy
      end

      it 'when permission not active returns false' do
        Permission.where(name: 'admin.monitoring').first.update!(active: false)

        expect(instance.send(:permission_and_permission_active?)).to be_falsey
      end
    end
  end

  describe '#valid_token_param?' do
    let(:token) { 'token' }
    let(:user)  { create(:admin) }

    before { Setting.set('monitoring_token', token) }

    describe 'when tokens match' do
      let(:params) { { token: token } }

      it 'returns true' do
        expect(instance.send(:valid_token_param?)).to be_truthy
      end
    end

    describe 'when tokens do not match' do
      let(:params) { { token: 'another_token' } }

      it 'returns false' do
        expect(instance.send(:valid_token_param?)).to be_falsey
      end
    end
  end

  describe '#monitoring_admin?' do
    context 'when has monitoring permission' do
      let(:user) { create(:admin) }

      it 'returns true' do
        expect(instance.send(:monitoring_admin?)).to be_truthy
      end
    end

    context 'when does not have monitoring permission' do
      let(:user) { create(:agent) }

      it 'returns false' do
        expect(instance.send(:monitoring_admin?)).to be_falsey
      end
    end

    context 'when no authorized user' do
      let(:user) { nil }

      it 'returns false' do
        expect(instance.send(:monitoring_admin?)).to be_falsey
      end
    end
  end
end
