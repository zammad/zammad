# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket zoom > Article creation', type: :system do
  context 'replying' do

    context 'Group without signature' do

      let(:ticket)       { create(:ticket) }
      let(:current_user) { create(:agent, password: 'test', groups: [ticket.group]) }

      before do
        # initial article to reply to
        create(:ticket_article, ticket: ticket)
      end

      it 'ensures that text input opens on multiple replies', authenticated_as: :current_user do
        visit "ticket/zoom/#{ticket.id}"

        2.times do |article_offset|
          articles_existing = 1
          articles_expected = articles_existing + (article_offset + 1)

          all('a[data-type=emailReply]').last.click

          # wait till input box expands completely
          find('.attachmentPlaceholder-label').in_fixed_position
          expect(page).to have_no_css('.attachmentPlaceholder-hint')

          find('.articleNewEdit-body').send_keys('Some reply')
          click '.js-submit'

          expect(page).to have_css('.ticket-article-item', count: articles_expected)
        end
      end
    end

    context 'Group with signature', authenticated_as: :user do
      let(:signature_body) { 'Sample signature here' }
      let(:signature)      { create(:signature, body: signature_body) }
      let(:group)          { create(:group, signature: signature) }

      let(:ticket) { create(:ticket, group: group) }
      let(:user) { create(:agent, groups: [group]) }

      before do
        visit "ticket/zoom/#{ticket.id}"
        click '.attachmentPlaceholder'
      end

      it 'removes signature when switching from email reply to phone' do
        click '.js-selectableTypes'
        click '.js-articleTypeItem[data-value=email]'

        within :richtext do
          expect(page).to have_text(signature_body)
        end

        click '.js-selectableTypes'
        click '.js-articleTypeItem[data-value=phone]'

        within :richtext do
          expect(page).to have_no_text(signature_body)
        end
      end

      it 'adds signature when switching from phone to email reply' do
        within :richtext do
          expect(page).to have_no_text(signature_body)
        end

        click '.js-selectableTypes'
        click '.js-articleTypeItem[data-value=email]'

        within :richtext do
          expect(page).to have_text(signature_body)
        end
      end
    end

    context 'to inbound phone call', authenticated_as: -> { agent }, current_user_id: -> { agent.id } do
      let(:agent)    { create(:agent, groups: [Group.first]) }
      let(:customer) { create(:customer) }
      let(:ticket)   { create(:ticket, customer: customer, group: agent.groups.first) }
      let!(:article) { create(:ticket_article, :inbound_phone, ticket: ticket) }

      before do
        create(:customer, active: false)
      end

      it 'goes to customer email' do
        visit "ticket/zoom/#{ticket.id}"

        within :active_ticket_article, article do
          click '.js-ArticleAction[data-type=emailReply]'
        end

        within :active_content do
          within '.article-new' do
            expect(find('[name=to]', visible: :all).value).to eq customer.email
          end
        end
      end

      it 'check active and inactive user in TO-field' do
        visit "ticket/zoom/#{ticket.id}"

        within :active_ticket_article, article do
          click '.js-ArticleAction[data-type=emailReply]'
        end

        within :active_content do
          within '.article-new' do
            find('[name=to] ~ .ui-autocomplete-input').fill_in with: '**'
          end
        end

        expect(page).to have_css('ul.ui-autocomplete > li.ui-menu-item', minimum: 2)
        expect(page).to have_css('ul.ui-autocomplete > li.ui-menu-item.is-inactive', count: 1)
      end
    end

    context 'to outbound phone call', authenticated_as: -> { agent }, current_user_id: -> { agent.id } do
      let(:agent)    { create(:agent, groups: [Group.first]) }
      let(:customer) { create(:customer) }
      let(:ticket)   { create(:ticket, customer: customer, group: agent.groups.first) }
      let!(:article) { create(:ticket_article, :outbound_phone, ticket: ticket) }

      it 'goes to customer email' do
        visit "ticket/zoom/#{ticket.id}"

        within :active_ticket_article, article do
          click '.js-ArticleAction[data-type=emailReply]'
        end

        within :active_content do
          within '.article-new' do
            expect(find('[name=to]', visible: :all).value).to eq customer.email
          end
        end
      end
    end

    context 'scrollPageHeader disappears when answering via email #3736' do
      let(:ticket) do
        ticket = create(:ticket, group: Group.first)
        create_list(:ticket_article, 15, ticket: ticket)
        ticket
      end

      before do
        visit "ticket/zoom/#{ticket.id}"
      end

      it 'does reset the scrollPageHeader on rerender of the ticket' do
        select User.find_by(email: 'admin@example.com').fullname, from: 'Owner'
        find('.js-textarea').send_keys('test 1234')
        find('.js-submit').click
        expect(page).to have_css('div.scrollPageHeader .js-ticketTitleContainer')
      end
    end
  end

  describe 'note visibility', authenticated_as: :customer do
    context 'when logged in as a customer' do
      let(:customer)        { create(:customer) }
      let(:ticket)          { create(:ticket, customer: customer) }
      let!(:ticket_article) { create(:ticket_article, ticket: ticket) }
      let!(:ticket_note)    { create(:ticket_article, ticket: ticket, internal: true, type_name: 'note') }

      it 'previously created private note is not visible' do
        visit "ticket/zoom/#{ticket_article.ticket.id}"

        expect(page).to have_no_selector(:active_ticket_article, ticket_note)
      end

      it 'previously created private note shows up via WS push' do
        visit "ticket/zoom/#{ticket_article.ticket.id}"
        ensure_websocket

        # make sure ticket is done loading and change will be pushed via WS
        find(:active_ticket_article, ticket_article)

        ticket_note.update!(internal: false)

        expect(page).to have_selector(:active_ticket_article, ticket_note)
      end
    end
  end

  # https://github.com/zammad/zammad/issues/3012
  describe 'article type selection' do
    context 'when logged in as a customer', authenticated_as: :customer do
      let(:customer) { create(:customer) }
      let(:ticket)   { create(:ticket, customer: customer) }

      it 'hides button for single choice' do
        visit "ticket/zoom/#{ticket.id}"

        find('.articleNewEdit-body').send_keys('Some reply')
        expect(page).to have_no_selector('.js-selectedArticleType')
      end
    end

    context 'when logged in as an agent' do
      let(:ticket) { create(:ticket, group: Group.find_by(name: 'Users')) }

      it 'shows button for multiple choices' do
        visit "ticket/zoom/#{ticket.id}"

        find('.articleNewEdit-body').send_keys('Some reply')
        expect(page).to have_css('.js-selectedArticleType')
      end
    end
  end

  context 'Article box opening on tickets with no changes #3789' do
    let(:ticket) { create(:ticket, group: Group.find_by(name: 'Users')) }

    before do
      visit "#ticket/zoom/#{ticket.id}"
    end

    it 'does not expand the article box without changes' do
      refresh
      sleep 3
      expect(page).to have_no_selector('form.article-add.is-open')
    end

    it 'does open and close by usage' do
      find('.js-writeArea').click
      find('.js-textarea').send_keys(' ')
      expect(page).to have_css('form.article-add.is-open')
      find('input#global-search').click
      expect(page).to have_no_selector('form.article-add.is-open')
    end

    it 'does open automatically when body is given from sidebar' do
      find('.js-textarea').send_keys('test')
      wait.until { Taskbar.find_by(key: "Ticket-#{ticket.id}").state.dig('article', 'body').present? }
      refresh
      expect(page).to have_css('form.article-add.is-open')
    end

    it 'does open automatically when attachment is given from sidebar' do
      page.find('input#fileUpload_1[data-initialized="true"]', visible: :all).set(Rails.root.join('test/data/mail/mail001.box'))
      wait.until { Taskbar.find_by(key: "Ticket-#{ticket.id}").attributes_with_association_ids['attachments'].present? }
      refresh
      expect(page).to have_css('form.article-add.is-open')
    end
  end

  describe 'Add confirmation dialog on visibility change of an article or in article creation #3924', authenticated_as: :authenticate do
    let(:ticket)  { create(:ticket, group: Group.find_by(name: 'Users')) }
    let(:article) { create(:ticket_article, ticket: ticket) }

    before do
      visit "#ticket/zoom/#{article.ticket.id}"
    end

    context 'when dialog is disabled' do
      def authenticate
        true
      end

      it 'does set the article internal and external for existing articles' do
        expect { page.find('.js-ArticleAction[data-type=internal]').click }.to change { article.reload.internal }.to(true)
        expect { page.find('.js-ArticleAction[data-type=public]').click }.to change { article.reload.internal }.to(false)
      end

      it 'does set the article internal and external for new article' do
        page.find('.js-writeArea').click(x: 5, y: 5)
        expect(page).to have_css('.article-new .icon-internal')
        expect(page).to have_no_css('.article-new .icon-public')

        page.find('.article-new .icon-internal').click
        expect(page).to have_no_css('.article-new .icon-internal')
        expect(page).to have_css('.article-new .icon-public')

        page.find('.article-new .icon-public').click
        expect(page).to have_css('.article-new .icon-internal')
        expect(page).to have_no_css('.article-new .icon-public')
      end
    end

    context 'when dialog is enabled' do
      def authenticate
        Setting.set('ui_ticket_zoom_article_visibility_confirmation_dialog', true)
        true
      end

      it 'does set the article internal and external for existing articles' do
        expect { page.find('.js-ArticleAction[data-type=internal]').click }.to change { article.reload.internal }.to(true)
        page.find('.js-ArticleAction[data-type=public]').click

        in_modal do
          expect { find('button[type=submit]').click }.to change { article.reload.internal }.to(false)
        end
      end

      it 'does set the article internal and external for new article' do
        page.find('.js-writeArea').click(x: 5, y: 5)
        expect(page).to have_css('.article-new .icon-internal')
        expect(page).to have_no_css('.article-new .icon-public')

        page.find('.article-new .icon-internal').click

        in_modal do
          find('button[type=submit]').click
        end

        expect(page).to have_no_css('.article-new .icon-internal')
        expect(page).to have_css('.article-new .icon-public')

        page.find('.article-new .icon-public').click
        expect(page).to have_css('.article-new .icon-internal')
        expect(page).to have_no_css('.article-new .icon-public')
      end
    end
  end
end
