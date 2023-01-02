# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Login > Public Links', authenticated_as: false, type: :system do
  context 'with showing public links' do
    let(:links) do
      first_link  = create(:public_link, title: 'Zammad Community', link: 'https://zammad.org')
      second_link = create(:public_link, title: 'Zammad Company', link: 'https://zammad.com')

      {
        first:  first_link,
        second: second_link,
      }
    end

    shared_examples 'displays public links in footer' do
      it 'shows public links in footer' do
        expect(page).to have_link('Zammad Community', href: 'https://zammad.org')
        expect(page).to have_link('Zammad Company', href: 'https://zammad.com')
      end
    end

    context 'with enabled user_create_account setting' do
      before do
        links
        setup(user_create_account: true)
      end

      include_examples 'displays public links in footer'
    end

    context 'with disabled user_create_account setting' do
      before do
        links
        setup(user_create_account: false)
      end

      include_examples 'displays public links in footer'
    end

    context 'with no public links' do
      before do
        visit_login
      end

      it 'does not show public links in footer' do
        link_tags = find_all(:xpath, '//a[@href="#signup"]//../a')

        expect(link_tags.size).to eq(1)
      end
    end
  end

  def setup(user_create_account:)
    Setting.set('user_create_account', user_create_account)

    visit_login
  end

  def visit_login
    visit '/'
    ensure_websocket
  end
end
