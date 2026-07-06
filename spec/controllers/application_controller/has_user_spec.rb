# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe ApplicationController::HasUser, type: :controller do
  controller(ApplicationController) do
    def index
      head :ok
    end
  end

  let(:admin)    { create(:admin) }
  let(:agent)    { create(:agent) }
  let(:customer) { create(:customer) }

  before do
    routes.draw { get 'index' => 'anonymous#index' }
    UserInfo.current_token = nil
  end

  describe '#set_user' do
    before do
      allow(controller).to receive(:request_header_from).and_return(customer.email)
    end

    # When current_user_set resets @_user_on_behalf = nil (so impersonate! runs fresh in set_user),
    # a stale UserInfo.current_token from a previous thread-pool request must not bleed into the
    # permissions? check - otherwise an admin whose token lacks admin.user would be denied.
    context 'when UserInfo.current_token is set to a stale token that lacks admin.user (simulates thread-pool reuse)' do
      let(:stale_token) { create(:token, user: agent, permissions: %w[ticket.agent]) }

      before { UserInfo.current_token = stale_token }

      it 'clears the stale token before the impersonation permission check so the admin can impersonate', :aggregate_failures do
        expect { controller.send(:current_user_set, admin, 'token_auth') }
          .not_to raise_error
        expect(controller.send(:current_user_on_behalf)).to eq(customer)
      end
    end
  end

  describe '#current_user_set' do
    before do
      # Make the From header visible without a live rack request
      allow(controller).to receive(:request_header_from).and_return(customer.email)
    end

    # The bug: @_user_on_behalf is only memoised when truthy, so a stale truthy
    # value from an earlier set_user call (e.g. for an admin) persists into the
    # next current_user_set call for a different user.  Without the fix the
    # memoised customer is returned by current_user_on_behalf without calling
    # impersonate! again, so the non-admin user inherits the impersonation state.
    context 'when @_user_on_behalf is already set from a prior set_user call' do
      before do
        controller.instance_variable_set(:@_user_on_behalf, customer)
        controller.instance_variable_set(:@_current_user, admin)
      end

      it 'clears the stale on-behalf user so impersonate! is re-evaluated for the new user' do
        expect { controller.send(:current_user_set, agent) }
          .to raise_error(Exceptions::Forbidden, %r{From})
      end
    end
  end
end
