# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket zoom', type: :system do

  describe 'owner auto-assignment', authenticated_as: :authenticate do
    let!(:ticket) { create(:ticket, group: Group.find_by(name: 'Users'), state: Ticket::State.find_by(name: 'new')) }
    let!(:session_user) { User.find_by(login: 'master@example.com') }

    context 'for agent disabled' do
      def authenticate
        Setting.set('ticket_auto_assignment', false)
        Setting.set('ticket_auto_assignment_selector', { condition: { 'ticket.state_id' => { operator: 'is', value: Ticket::State.by_category(:work_on).pluck(:id) } } })
        Setting.set('ticket_auto_assignment_user_ids_ignore', [])

        true
      end

      it 'do not assign ticket to current session user' do
        visit "#ticket/zoom/#{ticket.id}"

        within(:active_content) do
          expect(page).to have_css('select[name=owner_id]')
          expect(page).to have_select('owner_id',
                                      selected: '-',
                                      options:  ['-', 'Agent 1 Test', 'Test Master Agent'])
        end
      end
    end

    context 'for agent enabled' do
      def authenticate
        Setting.set('ticket_auto_assignment', true)
        Setting.set('ticket_auto_assignment_selector', { condition: { 'ticket.state_id' => { operator: 'is', value: Ticket::State.by_category(:work_on).pluck(:id) } } })
        Setting.set('ticket_auto_assignment_user_ids_ignore', setting_user_ids_ignore) if defined?(setting_user_ids_ignore)

        true
      end

      context 'with empty "ticket_auto_assignment_user_ids_ignore"' do
        it 'assigns ticket to current session user' do
          visit "#ticket/zoom/#{ticket.id}"

          within(:active_content) do
            expect(page).to have_css('.content.active select[name=owner_id]')
            expect(page).to have_select('owner_id',
                                        selected: session_user.fullname,
                                        options:  ['-', 'Agent 1 Test', 'Test Master Agent'])
          end
        end
      end

      context 'with "ticket_auto_assignment_user_ids_ignore" (as integer)' do
        let(:setting_user_ids_ignore) { session_user.id }

        it 'assigns ticket not to current session user' do
          visit "#ticket/zoom/#{ticket.id}"

          within(:active_content) do
            expect(page).to have_css('select[name=owner_id]')
            expect(page).to have_select('owner_id',
                                        selected: '-',
                                        options:  ['-', 'Agent 1 Test', 'Test Master Agent'])
          end
        end
      end

      context 'with "ticket_auto_assignment_user_ids_ignore" (as string)' do
        let(:setting_user_ids_ignore) { session_user.id.to_s }

        it 'assigns ticket not to current session user' do
          visit "#ticket/zoom/#{ticket.id}"

          within(:active_content) do
            expect(page).to have_css('select[name=owner_id]')
            expect(page).to have_select('owner_id',
                                        selected: '-',
                                        options:  ['-', 'Agent 1 Test', 'Test Master Agent'])
          end
        end
      end

      context 'with "ticket_auto_assignment_user_ids_ignore" (as [integer])' do
        let(:setting_user_ids_ignore) { [session_user.id] }

        it 'assigns ticket not to current session user' do
          visit "#ticket/zoom/#{ticket.id}"

          within(:active_content) do
            expect(page).to have_css('select[name=owner_id]')
            expect(page).to have_select('owner_id',
                                        selected: '-',
                                        options:  ['-', 'Agent 1 Test', 'Test Master Agent'])
          end
        end
      end

      context 'with "ticket_auto_assignment_user_ids_ignore" (as [string])' do
        let(:setting_user_ids_ignore) { [session_user.id.to_s] }

        it 'assigns ticket not to current session user' do
          visit "#ticket/zoom/#{ticket.id}"

          within(:active_content) do
            expect(page).to have_css('select[name=owner_id]')
            expect(page).to have_select('owner_id',
                                        selected: '-',
                                        options:  ['-', 'Agent 1 Test', 'Test Master Agent'])
          end
        end
      end

      context 'with "ticket_auto_assignment_user_ids_ignore" and other user ids' do
        let(:setting_user_ids_ignore) { [99_999, 999_999] }

        it 'assigns ticket to current session user' do
          visit "#ticket/zoom/#{ticket.id}"

          within(:active_content) do
            expect(page).to have_css('select[name=owner_id]')
            expect(page).to have_select('owner_id',
                                        selected: session_user.fullname,
                                        options:  ['-', 'Agent 1 Test', 'Test Master Agent'])
          end
        end
      end
    end
  end

  context 'when ticket has an attachment' do

    let(:group)           { Group.find_by(name: 'Users') }
    let(:ticket)          { create(:ticket, group: group) }
    let(:article)         { create(:ticket_article, ticket: ticket) }
    let(:attachment_name) { 'some_file.txt' }

    before do
      Store.add(
        object:        'Ticket::Article',
        o_id:          article.id,
        data:          'some content',
        filename:      attachment_name,
        preferences:   {
          'Content-Type' => 'text/plain',
        },
        created_by_id: 1,
      )
    end

    context 'article was already forwarded once' do
      before do
        visit "#ticket/zoom/#{ticket.id}"

        within(:active_content) do
          find('a[data-type=emailForward]').click

          click('.js-reset')
          have_no_css('.js-reset')
        end
      end

      it 'adds attachments when forwarding multiple times' do

        within(:active_content) do
          find('a[data-type=emailForward]').click
        end

        within('.js-writeArea') do
          expect(page).to have_text attachment_name
        end
      end
    end
  end

  context 'replying' do

    context 'Group without signature' do

      let(:ticket) { create(:ticket) }
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

    context 'to inbound phone call', current_user_id: -> { agent.id }, authenticated_as: -> { agent } do
      let(:agent)    { create(:agent, groups: [Group.first]) }
      let(:customer) { create(:agent) }
      let(:ticket)   { create(:ticket, customer: customer, group: agent.groups.first) }
      let!(:article) { create(:ticket_article, :inbound_phone, ticket: ticket) }

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

    context 'to outbound phone call', current_user_id: -> { agent.id }, authenticated_as: -> { agent } do
      let(:agent)    { create(:agent, groups: [Group.first]) }
      let(:customer) { create(:agent) }
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
  end

  describe 'delete article', authenticated_as: :authenticate do
    let(:group)       { Group.first }
    let(:admin)       { create :admin, groups: [group] }
    let(:agent)       { create :agent, groups: [group] }
    let(:other_agent) { create :agent, groups: [group] }
    let(:customer)    { create :customer }
    let(:article)     { send(item) }

    def authenticate
      Setting.set('ui_ticket_zoom_article_delete_timeframe', setting_delete_timeframe) if defined?(setting_delete_timeframe)
      article
      user
    end

    def article_communication
      create_ticket_article(sender_name: 'Agent', internal: false, type_name: 'email', updated_by: customer)
    end

    def article_note_self
      create_ticket_article(sender_name: 'Agent', internal: true, type_name: 'note', updated_by: user)
    end

    def article_note_other
      create_ticket_article(sender_name: 'Agent', internal: true, type_name: 'note', updated_by: other_agent)
    end

    def article_note_customer
      create_ticket_article(sender_name: 'Customer', internal: false, type_name: 'note', updated_by: customer)
    end

    def article_note_communication_self
      create(:ticket_article_type, name: 'note_communication', communication: true)

      create_ticket_article(sender_name: 'Agent', internal: true, type_name: 'note_communication', updated_by: user)
    end

    def article_note_communication_other
      create(:ticket_article_type, name: 'note_communication', communication: true)

      create_ticket_article(sender_name: 'Agent', internal: true, type_name: 'note_communication', updated_by: other_agent)
    end

    def create_ticket_article(sender_name:, internal:, type_name:, updated_by:)
      UserInfo.current_user_id = updated_by.id

      ticket = create :ticket, group: group, customer: customer

      create(:ticket_article,
             sender_name: sender_name, internal: internal, type_name: type_name, ticket: ticket,
             body: "to be deleted #{offset} #{item}",
             created_at: offset.ago, updated_at: offset.ago)
    end

    context 'going through full stack' do
      context 'as admin' do
        let(:user)   { admin }
        let(:item)   { 'article_note_self' }
        let(:offset) { 0.minutes }

        it 'succeeds' do
          ensure_websocket do
            visit "ticket/zoom/#{article.ticket.id}"
          end

          within :active_ticket_article, article do
            click '.js-ArticleAction[data-type=delete]'
          end

          in_modal do
            click '.js-submit'
          end

          wait.until_disappears { find :active_ticket_article, article, wait: false }
        end
      end
    end

    context 'verifying permissions matrix' do
      shared_examples 'according to permission matrix' do |item:, expects_visible:, offset:, description:|
        context "looking at #{description} #{item}" do
          let(:item)    { item }
          let(:offset)  { offset }
          let(:matcher) { expects_visible ? :have_css : :have_no_css }

          it expects_visible ? 'delete button is visible' : 'delete button is not visible' do
            visit "ticket/zoom/#{article.ticket.id}"

            within :active_ticket_article, article do
              expect(page).to send(matcher, '.js-ArticleAction[data-type=delete]', wait: 0)
            end
          end
        end
      end

      shared_examples 'deleting ticket article' do |item:, now:, later:, much_later:|
        include_examples 'according to permission matrix', item: item, expects_visible: now,        offset: 0.minutes,  description: 'just created'
        include_examples 'according to permission matrix', item: item, expects_visible: later,      offset: 6.minutes,  description: 'few minutes old'
        include_examples 'according to permission matrix', item: item, expects_visible: much_later, offset: 11.minutes, description: 'very old'
      end

      context 'as admin' do
        let(:user) { admin }

        include_examples 'deleting ticket article',
                         item: 'article_communication',
                         now: false, later: false, much_later: false

        include_examples 'deleting ticket article',
                         item: 'article_note_self',
                         now: true, later: true, much_later: false

        include_examples 'deleting ticket article',
                         item: 'article_note_other',
                         now: false, later: false, much_later: false

        include_examples 'deleting ticket article',
                         item: 'article_note_customer',
                         now: false, later: false, much_later: false

        include_examples 'deleting ticket article',
                         item: 'article_note_communication_self',
                         now: true, later: true, much_later: false

        include_examples 'deleting ticket article',
                         item: 'article_note_communication_other',
                         now: false, later: false, much_later: false
      end

      context 'as agent' do
        let(:user) { agent }

        include_examples 'deleting ticket article',
                         item: 'article_communication',
                         now: false, later: false, much_later: false

        include_examples 'deleting ticket article',
                         item: 'article_note_self',
                         now: true, later: true, much_later: false

        include_examples 'deleting ticket article',
                         item: 'article_note_other',
                         now: false, later: false, much_later: false

        include_examples 'deleting ticket article',
                         item: 'article_note_customer',
                         now: false, later: false, much_later: false

        include_examples 'deleting ticket article',
                         item: 'article_note_communication_self',
                         now: true, later: true, much_later: false

        include_examples 'deleting ticket article',
                         item: 'article_note_communication_other',
                         now: false, later: false, much_later: false
      end

      context 'as customer' do
        let(:user) { customer }

        include_examples 'deleting ticket article',
                         item: 'article_communication',
                         now: false, later: false, much_later: false

        include_examples 'deleting ticket article',
                         item: 'article_note_customer',
                         now: false, later: false, much_later: false

      end

      context 'with custom offset' do
        let(:setting_delete_timeframe) { 6_000 }

        context 'as admin' do
          let(:user) { admin }

          include_examples 'according to permission matrix', item: 'article_note_self', expects_visible: true,  offset: 5000.seconds, description: 'outside of delete timeframe'
          include_examples 'according to permission matrix', item: 'article_note_self', expects_visible: false, offset: 8000.seconds, description: 'outside of delete timeframe'
        end

        context 'as agent' do
          let(:user) { agent }

          include_examples 'according to permission matrix', item: 'article_note_self', expects_visible: true,  offset: 5000.seconds, description: 'outside of delete timeframe'
          include_examples 'according to permission matrix', item: 'article_note_self', expects_visible: false, offset: 8000.seconds, description: 'outside of delete timeframe'
        end
      end

      context 'with timeframe as 0' do
        let(:setting_delete_timeframe) { 0 }

        context 'as agent' do
          let(:user) { agent }

          include_examples 'according to permission matrix', item: 'article_note_self', expects_visible: true, offset: 99.days, description: 'long after'
        end
      end
    end

    context 'button is hidden on the go' do
      let(:setting_delete_timeframe) { 5 }

      let(:user)     { agent }
      let(:item)     { 'article_note_self' }
      let!(:article) { send(item) }
      let(:offset)   { 0.seconds }

      it 'successfully' do
        visit "ticket/zoom/#{article.ticket.id}"

        within :active_ticket_article, article do
          find '.js-ArticleAction[data-type=delete]' # make sure delete button did show up
          expect(page).to have_no_css('.js-ArticleAction[data-type=delete]')
        end
      end
    end
  end

  context 'S/MIME active', authenticated_as: :authenticate do
    let(:system_email_address) { 'smime1@example.com' }
    let(:email_address) { create(:email_address, email: system_email_address) }
    let(:group) { create(:group, email_address: email_address) }
    let(:agent_groups) { [group] }
    let(:agent) { create(:agent, groups: agent_groups) }

    let(:sender_email_address) { 'smime2@example.com' }
    let(:customer) { create(:customer, email: sender_email_address) }

    let!(:ticket) { create(:ticket, group: group, owner: agent, customer: customer) }

    def authenticate
      Setting.set('smime_integration', true)
      agent
    end

    context 'received mail' do

      context 'article meta information' do

        context 'success' do
          it 'shows encryption/sign information' do
            create(:ticket_article, preferences: {
                     security: {
                       type:       'S/MIME',
                       encryption: {
                         success: true,
                         comment: 'COMMENT_ENCRYPT_SUCCESS',
                       },
                       sign:       {
                         success: true,
                         comment: 'COMMENT_SIGN_SUCCESS',
                       },
                     }
                   }, ticket: ticket)

            visit "#ticket/zoom/#{ticket.id}"

            expect(page).to have_css('svg.icon-lock')
            expect(page).to have_css('svg.icon-signed')

            open_article_meta

            expect(page).to have_css('span', text: 'Encrypted')
            expect(page).to have_css('span', text: 'Signed')
            expect(page).to have_css('span[title=COMMENT_ENCRYPT_SUCCESS]')
            expect(page).to have_css('span[title=COMMENT_SIGN_SUCCESS]')
          end
        end

        context 'error' do

          it 'shows create information about encryption/sign failed' do
            create(:ticket_article, preferences: {
                     security: {
                       type:       'S/MIME',
                       encryption: {
                         success: false,
                         comment: 'Encryption failed because XXX',
                       },
                       sign:       {
                         success: false,
                         comment: 'Sign failed because XXX',
                       },
                     }
                   }, ticket: ticket)
            visit "#ticket/zoom/#{ticket.id}"

            expect(page).to have_css('svg.icon-not-signed')

            open_article_meta

            expect(page).to have_css('div.alert.alert--warning', text: 'Encryption failed because XXX')
            expect(page).to have_css('div.alert.alert--warning', text: 'Sign failed because XXX')
          end
        end
      end

      context 'certificate not present at time of arrival' do

        it 'retry' do
          smime1 = create(:smime_certificate, :with_private, fixture: system_email_address)
          smime2 = create(:smime_certificate, :with_private, fixture: sender_email_address)

          mail = Channel::EmailBuild.build(
            from:         sender_email_address,
            to:           system_email_address,
            body:         'somebody with some text',
            content_type: 'text/plain',
            security:     {
              type:       'S/MIME',
              sign:       {
                success: true,
              },
              encryption: {
                success: true,
              },
            },
          )

          smime1.destroy
          smime2.destroy

          parsed_mail = Channel::EmailParser.new.parse(mail.to_s)
          ticket, article, _user, _mail = Channel::EmailParser.new.process({ group_id: group.id }, parsed_mail['raw'])
          expect(Ticket::Article.find(article.id).body).to eq('no visible content')

          create(:smime_certificate, fixture: sender_email_address)
          create(:smime_certificate, :with_private, fixture: system_email_address)

          visit "#ticket/zoom/#{ticket.id}"
          expect(page).to have_no_css('.article-content', text: 'somebody with some text')
          click '.js-securityRetryProcess'
          expect(page).to have_css('.article-content', text: 'somebody with some text')
        end
      end
    end

    context 'replying', authenticated_as: :setup_and_authenticate do

      def setup_and_authenticate
        create(:ticket_article, ticket: ticket, from: customer.email)

        create(:smime_certificate, :with_private, fixture: system_email_address)
        create(:smime_certificate, fixture: sender_email_address)

        authenticate
      end

      it 'plain' do
        visit "#ticket/zoom/#{ticket.id}"

        all('a[data-type=emailReply]').last.click
        find('.articleNewEdit-body').send_keys('Test')

        expect(page).to have_css('.js-securityEncrypt.btn--active', wait: 5)
        expect(page).to have_css('.js-securitySign.btn--active', wait: 5)

        click '.js-securityEncrypt'
        click '.js-securitySign'

        click '.js-submit'
        expect(page).to have_css('.ticket-article-item', count: 2)

        expect(Ticket::Article.last.preferences['security']['encryption']['success']).to be nil
        expect(Ticket::Article.last.preferences['security']['sign']['success']).to be nil
      end

      it 'signed' do
        visit "#ticket/zoom/#{ticket.id}"

        all('a[data-type=emailReply]').last.click
        find('.articleNewEdit-body').send_keys('Test')

        expect(page).to have_css('.js-securityEncrypt.btn--active', wait: 5)
        expect(page).to have_css('.js-securitySign.btn--active', wait: 5)

        click '.js-securityEncrypt'

        click '.js-submit'
        expect(page).to have_css('.ticket-article-item', count: 2)

        expect(Ticket::Article.last.preferences['security']['encryption']['success']).to be nil
        expect(Ticket::Article.last.preferences['security']['sign']['success']).to be true
      end

      it 'encrypted' do
        visit "#ticket/zoom/#{ticket.id}"

        all('a[data-type=emailReply]').last.click
        find('.articleNewEdit-body').send_keys('Test')

        expect(page).to have_css('.js-securityEncrypt.btn--active', wait: 5)
        expect(page).to have_css('.js-securitySign.btn--active', wait: 5)

        click '.js-securitySign'

        click '.js-submit'
        expect(page).to have_css('.ticket-article-item', count: 2)

        expect(Ticket::Article.last.preferences['security']['encryption']['success']).to be true
        expect(Ticket::Article.last.preferences['security']['sign']['success']).to be nil
      end

      it 'signed and encrypted' do
        visit "#ticket/zoom/#{ticket.id}"

        all('a[data-type=emailReply]').last.click
        find('.articleNewEdit-body').send_keys('Test')

        expect(page).to have_css('.js-securityEncrypt.btn--active', wait: 5)
        expect(page).to have_css('.js-securitySign.btn--active', wait: 5)

        click '.js-submit'
        expect(page).to have_css('.ticket-article-item', count: 2)

        expect(Ticket::Article.last.preferences['security']['encryption']['success']).to be true
        expect(Ticket::Article.last.preferences['security']['sign']['success']).to be true
      end
    end

    context 'Group default behavior' do

      let(:smime_config) { {} }

      def authenticate
        Setting.set('smime_integration', true)

        Setting.set('smime_config', smime_config)

        create(:ticket_article, ticket: ticket, from: customer.email)

        create(:smime_certificate, :with_private, fixture: system_email_address)
        create(:smime_certificate, fixture: sender_email_address)

        agent
      end

      shared_examples 'security defaults example' do |sign:, encrypt:|

        it "security defaults sign: #{sign}, encrypt: #{encrypt}" do
          within(:active_content) do
            encrypt_button = find('.js-securityEncrypt', wait: 5)
            sign_button    = find('.js-securitySign', wait: 5)

            await_empty_ajax_queue

            active_button_class = '.btn--active'
            expect(encrypt_button.matches_css?(active_button_class, wait: 2)).to be(encrypt)
            expect(sign_button.matches_css?(active_button_class, wait: 2)).to be(sign)
          end
        end
      end

      shared_examples 'security defaults' do |sign:, encrypt:|

        before do
          visit "#ticket/zoom/#{ticket.id}"

          within(:active_content) do
            all('a[data-type=emailReply]').last.click
            find('.articleNewEdit-body').send_keys('Test')

            await_empty_ajax_queue
          end
        end

        include_examples 'security defaults example', sign: sign, encrypt: encrypt
      end

      shared_examples 'security defaults group change' do |sign:, encrypt:|

        before do
          visit "#ticket/zoom/#{ticket.id}"

          within(:active_content) do
            all('a[data-type=emailReply]').last.click
            find('.articleNewEdit-body').send_keys('Test')

            await_empty_ajax_queue

            select new_group.name, from: 'group_id'
          end
        end

        include_examples 'security defaults example', sign: sign, encrypt: encrypt
      end

      context 'not configured' do
        it_behaves_like 'security defaults', sign: true, encrypt: true
      end

      context 'configuration present' do

        let(:smime_config) do
          {
            'group_id' => group_defaults
          }
        end

        let(:group_defaults) do
          {
            'default_encryption' => {
              group.id.to_s => default_encryption,
            },
            'default_sign'       => {
              group.id.to_s => default_sign,
            }
          }
        end

        let(:default_sign) { true }
        let(:default_encryption) { true }

        shared_examples 'sign and encrypt variations' do |check_examples_name|

          it_behaves_like check_examples_name, sign: true, encrypt: true

          context 'no value' do
            let(:group_defaults) { {} }

            it_behaves_like check_examples_name, sign: true, encrypt: true
          end

          context 'signing disabled' do
            let(:default_sign) { false }

            it_behaves_like check_examples_name, sign: false, encrypt: true
          end

          context 'encryption disabled' do
            let(:default_encryption) { false }

            it_behaves_like check_examples_name, sign: true, encrypt: false
          end
        end

        context 'same Group' do
          it_behaves_like 'sign and encrypt variations', 'security defaults'
        end

        context 'Group change' do
          let(:new_group) { create(:group, email_address: email_address) }

          let(:agent_groups) { [group, new_group] }

          let(:group_defaults) do
            {
              'default_encryption' => {
                new_group.id.to_s => default_encryption,
              },
              'default_sign'       => {
                new_group.id.to_s => default_sign,
              }
            }
          end

          it_behaves_like 'sign and encrypt variations', 'security defaults group change'
        end
      end
    end
  end

  describe 'linking Knowledge Base answer' do
    include_context 'basic Knowledge Base'

    let(:ticket)      { create :ticket, group: Group.find_by(name: 'Users') }
    let(:answer)      { published_answer }
    let(:translation) { answer.translations.first }

    shared_examples 'verify linking' do
      it 'allows to look up an answer' do
        visit "#ticket/zoom/#{ticket.id}"

        within :active_content do
          within '.link_kb_answers' do
            find('.js-add').click

            find('.js-input').send_keys translation.title

            find(%(li[data-value="#{translation.id}"])).click

            expect(find('.link_kb_answers ol')).to have_text translation.title
          end
        end
      end
    end

    context 'with ES', searchindex: true, authenticated_as: :authenticate do
      def authenticate
        configure_elasticsearch(required: true, rebuild: true) do
          answer
        end

        true
      end

      include_examples 'verify linking'
    end

    context 'without ES', authenticated_as: :authenticate do
      def authenticate
        answer
        true
      end

      include_examples 'verify linking'
    end
  end

  describe 'forwarding article with an image' do
    let(:ticket_article_body) do
      filename = 'squares.png'
      file     = File.binread(Rails.root.join("spec/fixtures/image/#{filename}"))
      ext      = File.extname(filename)[1...]
      base64   = Base64.encode64(file).delete("\n")

      "<img style='width: 1004px; max-width: 100%;' src=\\\"data:image/#{ext};base64,#{base64}\\\"><br>"
    end

    def current_ticket
      Ticket.find current_url.split('/').last
    end

    def create_ticket
      visit '#ticket/create'

      within :active_content do
        find('[data-type=email-out]').click

        find('[name=title]').fill_in with: 'Title'
        find('[name=customer_id_completion]').fill_in with: 'customer@example.com'
        find('[name=group_id]').select 'Users'
        find(:richtext).execute_script "this.innerHTML = \"#{ticket_article_body}\""
        find('.js-submit').click
      end

      await_empty_ajax_queue
    end

    def forward
      within :active_content do
        click '.js-ArticleAction[data-type=emailForward]'
        fill_in 'To', with: 'customer@example.com'
        find('.js-submit').click
      end

      await_empty_ajax_queue
    end

    def images_identical?(image_a, image_b)
      return false if image_a.height != image_b.height
      return false if image_a.width != image_b.width

      image_a.height.times do |y|
        image_a.row(y).each_with_index do |pixel, x|
          return false if pixel != image_b[x, y]
        end
      end

      true
    end

    it 'keeps image intact' do
      create_ticket
      forward

      images = current_ticket.articles.map do |article|
        ChunkyPNG::Image.from_string article.attachments.first.content
      end

      expect(images_identical?(images.first, images.second)).to be(true)
    end
  end

  # https://github.com/zammad/zammad/issues/3335
  context 'ticket state sort order maintained when locale is de-de', authenticated_as: :authenticate do
    def authenticate
      user.preferences[:locale] = 'de-de'
      user
    end

    context 'when existing ticket is open' do
      let(:user) { create(:customer) }
      let(:ticket) { create(:ticket, customer: user) }

      it 'shows ticket state dropdown options in sorted order, with new at the end' do
        visit "ticket/zoom/#{ticket.id}"

        await_empty_ajax_queue
        expect(all('select[name=state_id] option').map(&:text)).to eq(%w[geschlossen offen neu])
      end
    end

    context 'when a new ticket is created' do
      let(:user) { create(:agent, groups: [permitted_group]) }
      let(:permitted_group) { create(:group) }

      it 'shows ticket state dropdown options in sorted order, with new in sorted position' do
        visit 'ticket/create'

        await_empty_ajax_queue
        expect(all('select[name=state_id] option').map(&:text)).to eq ['-', 'geschlossen', 'neu', 'offen', 'warten auf Erinnerung', 'warten auf schliessen']
      end
    end
  end

  context 'object manager attribute permission view' do
    let!(:group_users) { Group.find_by(name: 'Users') }

    shared_examples 'shows attributes and values for agent view and editable' do
      it 'shows attributes and values for agent view and editable', authenticated_as: :current_user do
        visit "ticket/zoom/#{ticket.id}"
        refresh # refresh to have assets generated for ticket

        expect(page).to have_select('state_id', options: ['new', 'open', 'pending reminder', 'pending close', 'closed'])
        expect(page).to have_select('priority_id')
        expect(page).to have_select('owner_id')
        expect(page).to have_css('div.tabsSidebar-tab[data-tab=customer]')
      end
    end

    shared_examples 'shows attributes and values for agent view but disabled' do
      it 'shows attributes and values for agent view but disabled', authenticated_as: :current_user do
        visit "ticket/zoom/#{ticket.id}"
        refresh # refresh to have assets generated for ticket

        expect(page).to have_css('select[name=state_id][disabled]')
        expect(page).to have_css('select[name=priority_id][disabled]')
        expect(page).to have_css('select[name=owner_id][disabled]')
        expect(page).to have_css('div.tabsSidebar-tab[data-tab=customer]')
      end
    end

    shared_examples 'shows attributes and values for customer view' do
      it 'shows attributes and values for customer view', authenticated_as: :current_user do
        visit "ticket/zoom/#{ticket.id}"
        refresh # refresh to have assets generated for ticket

        expect(page).to have_select('state_id', options: %w[new open closed])
        expect(page).to have_no_select('priority_id')
        expect(page).to have_no_select('owner_id')
        expect(page).to have_no_css('div.tabsSidebar-tab[data-tab=customer]')
      end
    end

    context 'as customer' do
      let!(:current_user) { create(:customer) }
      let(:ticket) { create(:ticket, customer: current_user) }

      include_examples 'shows attributes and values for customer view'
    end

    context 'as agent with full permissions' do
      let(:current_user) { create(:agent, groups: [ group_users ] ) }
      let(:ticket) { create(:ticket, group: group_users ) }

      include_examples 'shows attributes and values for agent view and editable'
    end

    context 'as agent with change permissions' do
      let!(:current_user) { create(:agent) }
      let(:ticket) { create(:ticket, group: group_users) }

      before do
        current_user.group_names_access_map = {
          group_users.name => %w[read change],
        }
      end

      include_examples 'shows attributes and values for agent view and editable'
    end

    context 'as agent with read permissions' do
      let!(:current_user) { create(:agent) }
      let(:ticket) { create(:ticket, group: group_users) }

      before do
        current_user.group_names_access_map = {
          group_users.name => 'read',
        }
      end

      include_examples 'shows attributes and values for agent view but disabled'
    end

    context 'as agent+customer with full permissions' do
      let!(:current_user) { create(:agent_and_customer, groups: [ group_users ] ) }

      context 'normal ticket' do
        let(:ticket) { create(:ticket, group: group_users ) }

        include_examples 'shows attributes and values for agent view and editable'
      end

      context 'ticket where current_user is also customer' do
        let(:ticket) { create(:ticket, customer: current_user, group: group_users ) }

        include_examples 'shows attributes and values for agent view and editable'
      end
    end

    context 'as agent+customer with change permissions' do
      let!(:current_user) { create(:agent_and_customer) }

      before do
        current_user.group_names_access_map = {
          group_users.name => %w[read change],
        }
      end

      context 'normal ticket' do
        let(:ticket) { create(:ticket, group: group_users) }

        include_examples 'shows attributes and values for agent view and editable'
      end

      context 'ticket where current_user is also customer' do
        let(:ticket) { create(:ticket, customer: current_user, group: group_users) }

        include_examples 'shows attributes and values for agent view and editable'
      end
    end

    context 'as agent+customer with read permissions' do
      let!(:current_user) { create(:agent_and_customer) }

      before do
        current_user.group_names_access_map = {
          group_users.name => 'read',
        }
      end

      context 'normal ticket' do
        let(:ticket) { create(:ticket, group: group_users) }

        include_examples 'shows attributes and values for agent view but disabled'
      end

      context 'ticket where current_user is also customer' do
        let(:ticket) { create(:ticket, customer: current_user, group: group_users) }

        include_examples 'shows attributes and values for agent view but disabled'
      end
    end

    context 'as agent+customer but only customer for the ticket (no agent access)' do
      let!(:current_user) { create(:agent_and_customer) }
      let(:ticket) { create(:ticket, customer: current_user) }

      include_examples 'shows attributes and values for customer view'
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

        # make sure ticket is done loading and change will be pushed via WS
        find(:active_ticket_article, ticket_article)
        await_empty_ajax_queue

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
        expect(page).to have_selector('.js-selectedArticleType')
      end
    end
  end

  # https://github.com/zammad/zammad/issues/3260
  describe 'next in overview macro changes URL', authenticated_as: :authenticate do
    let(:next_ticket) { create(:ticket, title: 'next Ticket', group: Group.first) }
    let(:macro)       { create(:macro, name: 'next macro', ux_flow_next_up: 'next_from_overview') }

    def authenticate
      next_ticket && macro

      true
    end

    it 'to next Ticket ID' do
      visit 'ticket/view/all_unassigned'
      click_on 'Welcome to Zammad!'
      click '.js-openDropdownMacro'
      find(:macro, macro.id).click
      wait(5, interval: 1).until_constant { current_url }

      expect(current_url).to include("ticket/zoom/#{next_ticket.id}")
    end
  end

  # https://github.com/zammad/zammad/issues/3279
  describe 'previous/next clickability when at last or first ticket' do
    let(:ticket_a)          { create(:ticket, title: 'ticket a', group: Group.first) }
    let(:ticket_b)          { create(:ticket, title: 'ticket b', group: Group.first) }

    before do
      ticket_a && ticket_b

      visit 'ticket/view/all_unassigned'
    end

    it 'previous is not clickable for the first item' do
      open_nth_item(0)

      expect { click '.pagination .previous' }.not_to change { current_url }
    end

    it 'next is clickable for the first item' do
      open_nth_item(0)

      expect { click '.pagination .next' }.to change { current_url }
    end

    it 'previous is clickable for the middle item' do
      open_nth_item(1)

      expect { click '.pagination .previous' }.to change { current_url }
    end

    it 'next is clickable for the middle item' do
      open_nth_item(1)

      expect { click '.pagination .next' }.to change { current_url }
    end

    it 'previous is clickable for the last item' do
      open_nth_item(2)

      expect { click '.pagination .previous' }.to change { current_url }
    end

    it 'next is not clickable for the last item' do
      open_nth_item(2)

      expect { click '.pagination .next' }.not_to change { current_url }
    end

    def open_nth_item(nth)
      within :active_content do
        find_all('.table tr.item a[href^="#ticket/zoom"]')[nth].click
      end

      await_empty_ajax_queue
    end
  end

  # https://github.com/zammad/zammad/issues/3267
  describe 'previous/next buttons are added when open ticket is opened from overview' do
    let(:ticket_a)          { create(:ticket, title: 'ticket a', group: Group.first) }
    let(:ticket_b)          { create(:ticket, title: 'ticket b', group: Group.first) }

    # prepare an opened ticket and go to overview
    before do
      ticket_a && ticket_b

      visit "ticket/zoom/#{ticket_a.id}"

      await_empty_ajax_queue

      visit 'ticket/view/all_unassigned'
    end

    it 'adds previous/next buttons to existing ticket' do
      within :active_content do
        click_on ticket_a.title

        expect(page).to have_css('.pagination-counter')
      end
    end

    it 'keeps previous/next buttons when navigating to overview ticket from elsewhere' do
      within :active_content do
        click_on ticket_a.title
        visit 'dashboard'
        visit "ticket/zoom/#{ticket_a.id}"

        expect(page).to have_css('.pagination-counter')
      end
    end
  end

  # https://github.com/zammad/zammad/issues/2942
  describe 'attachments are lost in specific conditions' do
    let(:ticket) { create(:ticket, group: Group.first) }

    it 'attachment is retained when forwarding a fresh article' do
      ensure_websocket do
        visit "ticket/zoom/#{ticket.id}"
      end

      # add an article, forcing reset of form_id

      # click in the upper most upper left corner of the article create textbox
      # (that works for both Firefox and Chrome)
      # to avoid clicking on attachment upload
      find('.js-writeArea').click({ x: 5, y: 5 })

      # wait for propagateOpenTextarea to be completed
      find('.attachmentPlaceholder-label').in_fixed_position
      expect(page).to have_no_css('.attachmentPlaceholder-hint')

      # write article content
      find('.articleNewEdit-body').send_keys('Some reply')
      click '.js-submit'

      # wait for article to be added to the page
      expect(page).to have_css('.ticket-article-item', count: 1)
      await_empty_ajax_queue

      # create a on-the-fly article with attachment that will get pushed to open browser
      article1 = create(:ticket_article, ticket: ticket)
      Store.add(
        object:        'Ticket::Article',
        o_id:          article1.id,
        data:          'some content',
        filename:      'some_file.txt',
        preferences:   {
          'Content-Type' => 'text/plain',
        },
        created_by_id: 1,
      )

      # wait for article to be added to the page
      expect(page).to have_css('.ticket-article-item', count: 2, wait: 10)
      await_empty_ajax_queue

      # click on forward of created article
      within :active_ticket_article, article1 do
        find('a[data-type=emailForward]').click
      end

      # wait for propagateOpenTextarea to be completed
      find('.attachmentPlaceholder-label').in_fixed_position
      expect(page).to have_no_css('.attachmentPlaceholder-hint')

      # fill forward information and create article
      fill_in 'To', with: 'forward@example.org'
      find('.articleNewEdit-body').send_keys('Forwarding with the attachment')
      click '.js-submit'

      # wait for article to be added to the page
      await_empty_ajax_queue
      expect(page).to have_css('.ticket-article-item', count: 3)

      # check if attachment was forwarded successfully
      within :active_ticket_article, ticket.reload.articles.last do
        within '.attachments--list' do
          expect(page).to have_text('some_file.txt')
        end
      end
    end
  end

  describe 'mentions' do
    context 'when logged in as agent' do
      let(:ticket) { create(:ticket, group: Group.find_by(name: 'Users')) }
      let!(:other_agent) { create(:agent, groups: [Group.find_by(name: 'Users')]) }

      it 'can subscribe and unsubscribe' do
        ensure_websocket do
          visit "ticket/zoom/#{ticket.id}"

          click '.js-subscriptions .js-subscribe input'
          expect(page).to have_selector('.js-subscriptions .js-unsubscribe input', wait: 10)
          expect(page).to have_selector('.js-subscriptions span.avatar', wait: 10)

          click '.js-subscriptions .js-unsubscribe input'
          expect(page).to have_selector('.js-subscriptions .js-subscribe input', wait: 10)
          expect(page).to have_no_selector('.js-subscriptions span.avatar', wait: 10)

          create(:mention, mentionable: ticket, user: other_agent)
          expect(page).to have_selector('.js-subscriptions span.avatar', wait: 10)

          # check history for mention entries
          click 'h2.sidebar-header-headline.js-headline'
          click 'li[data-type=ticket-history] a'
          expect(page).to have_text('created Mention', wait: 10)
          expect(page).to have_text('removed Mention', wait: 10)
        end
      end
    end
  end

  # https://github.com/zammad/zammad/issues/2671
  describe 'Pending time field in ticket sidebar', authenticated_as: :customer do
    let(:customer) { create(:customer) }
    let(:ticket)   { create(:ticket, customer: customer, pending_time: 1.day.from_now, state: Ticket::State.lookup(name: 'pending reminder')) }

    it 'not shown to customer' do
      visit "ticket/zoom/#{ticket.id}"
      await_empty_ajax_queue

      within :active_content do
        expect(page).to have_no_css('.controls[data-name=pending_time]')
      end
    end
  end

  describe 'Pending time field in ticket sidebar as agent' do
    before do
      ticket.update(pending_time: 1.day.from_now, state: Ticket::State.lookup(name: 'pending reminder'))

      visit "ticket/zoom/#{ticket.id}"
      await_empty_ajax_queue
    end

    let(:ticket) { Ticket.first }
    let(:elem)   { find('.js-timepicker') }

    # has to run asynchronously to keep both Firefox and Safari
    # https://github.com/zammad/zammad/issues/3414
    # https://github.com/zammad/zammad/issues/2887
    context 'when clicking timepicker component' do
      it 'in the first half, hours selected' do
        within :active_content do
          elem.click({ x: 10, y: 20 })
          expect(elem).to have_selection(0..2)
        end
      end

      it 'in the second half, minutes selected' do
        within :active_content do
          elem.click({ x: 35, y: 20 })
          expect(elem).to have_selection(3..5)
        end
      end
    end

    matcher :have_selection do
      match { starts_at == expected.begin && ends_at == expected.end }

      def starts_at
        actual.evaluate_script 'this.selectionStart'
      end

      def ends_at
        actual.evaluate_script 'this.selectionEnd'
      end
    end
  end

  describe 'Article ID URL / link' do
    let(:ticket) { create(:ticket, group: Group.first) }
    let!(:article) { create(:'ticket/article', ticket: ticket) }
    let(:url) { "#{Setting.get('http_type')}://#{Setting.get('fqdn')}/#ticket/zoom/#{ticket.id}/#{article.id}" }

    it 'shows Article direct link' do

      ensure_websocket do
        visit "ticket/zoom/#{ticket.id}"
        await_empty_ajax_queue

        within :active_ticket_article, article do
          expect(page).to have_css(%(a[href="#{url}"]))
        end
      end
    end

    context 'when multiple Articles are present' do

      let(:article_count) { 20 }
      let(:article_at_the_top) { ticket.articles.first }
      let(:article_in_the_middle) { ticket.articles[ article_count / 2 ] }
      let(:article_at_the_bottom) { ticket.articles.last }

      before do
        article_count.times do
          create(:'ticket/article', ticket: ticket, body: SecureRandom.uuid)
        end
      end

      it 'scrolls to given Article ID' do
        ensure_websocket do
          visit "ticket/zoom/#{ticket.id}/#{article_in_the_middle.id}"
          await_empty_ajax_queue
          # workaround because browser scrolls in test initially to the bottom
          # maybe because the articles are not present?!
          refresh

          # scroll to article in the middle of the page
          within :active_content do
            find("div#article-content-#{article_in_the_middle.id}").in_fixed_position(wait: 0.5)

            expect(find("div#article-content-#{article_at_the_top.id}")).to be_obscured
            expect(find("div#article-content-#{article_in_the_middle.id}")).not_to be_obscured
            expect(find("div#article-content-#{article_at_the_bottom.id}")).to be_obscured
          end

          # scroll to article at the top of the page
          visit "ticket/zoom/#{ticket.id}/#{article_at_the_top.id}"
          await_empty_ajax_queue
          within :active_content do
            find("div#article-content-#{article_in_the_middle.id}").in_fixed_position(wait: 0.5)

            expect(find("div#article-content-#{article_at_the_top.id}")).not_to be_obscured
            expect(find("div#article-content-#{article_in_the_middle.id}")).to be_obscured
            expect(find("div#article-content-#{article_at_the_bottom.id}")).to be_obscured
          end

          # scroll to article at the bottom of the page
          visit "ticket/zoom/#{ticket.id}/#{article_at_the_bottom.id}"
          await_empty_ajax_queue
          within :active_content do
            find("div#article-content-#{article_in_the_middle.id}").in_fixed_position(wait: 0.5)

            expect(find("div#article-content-#{article_at_the_top.id}")).to be_obscured
            expect(find("div#article-content-#{article_in_the_middle.id}")).to be_obscured
            expect(find("div#article-content-#{article_at_the_bottom.id}")).not_to be_obscured
          end
        end
      end
    end

    context 'when long articles are present' do
      it 'will properly show the "See more" link if you switch between the ticket and the dashboard on new articles' do
        ensure_websocket do
          visit "ticket/zoom/#{ticket.id}"
          await_empty_ajax_queue

          visit 'dashboard'
          expect(page).to have_css("a.js-dashboardMenuItem[data-key='Dashboard'].is-active", wait: 10)
          article_id = create(:'ticket/article', ticket: ticket, body: "#{SecureRandom.uuid} #{"lorem ipsum\n" * 200}")
          expect(page).to have_css('div.tasks a.is-modified', wait: 10)

          visit "ticket/zoom/#{ticket.id}"
          within :active_content do
            expect(find("div#article-content-#{article_id.id}")).to have_text('See more')
          end
        end
      end
    end
  end

  describe 'Macros', authenticated_as: :authenticate do
    let(:macro_body) { 'macro <b>body</b>' }
    let(:macro) { create :macro, perform: { 'article.note' => { 'body' => macro_body, 'internal' => 'true', 'subject' => 'macro note' } } }
    let!(:ticket) { create(:ticket, group: Group.find_by(name: 'Users')) }

    def authenticate
      macro
      true
    end

    it 'does html macro by default' do
      visit "ticket/zoom/#{ticket.id}"
      find('.js-openDropdownMacro').click
      find(:macro, macro.id).click
      await_empty_ajax_queue

      expect(ticket.reload.articles.last.body).to eq(macro_body)
      expect(ticket.reload.articles.last.content_type).to eq('text/html')
    end
  end

  describe 'object manager attributes maxlength', authenticated_as: :authenticate, db_strategy: :reset do
    let(:ticket) { create(:ticket, group: Group.find_by(name: 'Users')) }

    def authenticate
      ticket
      create :object_manager_attribute_text, name: 'maxtest', display: 'maxtest', screens: attributes_for(:required_screen), data_option: {
        'type'      => 'text',
        'maxlength' => 3,
        'null'      => true,
        'translate' => false,
        'default'   => '',
        'options'   => {},
        'relation'  => '',
      }
      ObjectManager::Attribute.migration_execute
      true
    end

    it 'checks ticket zoom' do
      visit "ticket/zoom/#{ticket.id}"
      within(:active_content) do
        fill_in 'maxtest', with: 'hellu'
        expect(page.find_field('maxtest').value).to eq('hel')
      end
    end
  end

  describe 'GitLab Integration', :integration, authenticated_as: :authenticate do
    let!(:ticket) { create(:ticket, group: Group.find_by(name: 'Users')) }

    before(:all) do # rubocop:disable RSpec/BeforeAfterAll
      required_envs = %w[GITLAB_ENDPOINT GITLAB_APITOKEN]
      required_envs.each do |key|
        skip("NOTICE: Missing environment variable #{key} for test! (Please fill up: #{required_envs.join(' && ')})") if ENV[key].blank?
      end
    end

    def authenticate
      Setting.set('gitlab_integration', true)
      Setting.set('gitlab_config', {
                    api_token: ENV['GITLAB_APITOKEN'],
                    endpoint:  ENV['GITLAB_ENDPOINT'],
                  })
      true
    end

    it 'creates links and removes them' do
      visit "#ticket/zoom/#{ticket.id}"
      within(:active_content) do

        # switch to GitLab sidebar
        click('.tabsSidebar-tab[data-tab=gitlab]')
        click('.sidebar-header-headline.js-headline')

        # add issue
        click_on 'Link issue'
        fill_in 'link', with: ENV['GITLAB_ISSUE_LINK']
        click_on 'Submit'
        await_empty_ajax_queue

        # verify issue
        content = find('.sidebar-git-issue-content')
        expect(content).to have_text('#1 Example issue')
        expect(content).to have_text('critical')
        expect(content).to have_text('special')
        expect(content).to have_text('important milestone')
        expect(content).to have_text('zammad-robot')

        expect(ticket.reload.preferences[:gitlab][:issue_links][0]).to eq(ENV['GITLAB_ISSUE_LINK'])

        # check sidebar counter increased to 1
        expect(find('.tabsSidebar-tab[data-tab=gitlab] .js-tabCounter')).to have_text('1')

        # delete issue
        click(".sidebar-git-issue-delete span[data-issue-id='#{ENV['GITLAB_ISSUE_LINK']}']")
        await_empty_ajax_queue

        content = find('.sidebar[data-tab=gitlab] .sidebar-content')
        expect(content).to have_text('No linked issues')
        expect(ticket.reload.preferences[:gitlab][:issue_links][0]).to be nil

        # check that counter got removed
        expect(page).to have_no_selector('.tabsSidebar-tab[data-tab=gitlab] .js-tabCounter')
      end
    end
  end

  describe 'GitHub Integration', :integration, authenticated_as: :authenticate do
    let!(:ticket) { create(:ticket, group: Group.find_by(name: 'Users')) }

    before(:all) do # rubocop:disable RSpec/BeforeAfterAll
      required_envs = %w[GITHUB_ENDPOINT GITHUB_APITOKEN]
      required_envs.each do |key|
        skip("NOTICE: Missing environment variable #{key} for test! (Please fill up: #{required_envs.join(' && ')})") if ENV[key].blank?
      end
    end

    def authenticate
      Setting.set('github_integration', true)
      Setting.set('github_config', {
                    api_token: ENV['GITHUB_APITOKEN'],
                    endpoint:  ENV['GITHUB_ENDPOINT'],
                  })
      true
    end

    it 'creates links and removes them' do
      visit "#ticket/zoom/#{ticket.id}"
      within(:active_content) do

        # switch to GitHub sidebar
        click('.tabsSidebar-tab[data-tab=github]')
        click('.sidebar-header-headline.js-headline')

        # add issue
        click_on 'Link issue'
        fill_in 'link', with: ENV['GITHUB_ISSUE_LINK']
        click_on 'Submit'
        await_empty_ajax_queue

        # verify issue
        content = find('.sidebar-git-issue-content')
        expect(content).to have_text('#1575 GitHub integration')
        expect(content).to have_text('feature backlog')
        expect(content).to have_text('integration')
        expect(content).to have_text('4.0')
        expect(content).to have_text('Thorsten')

        expect(ticket.reload.preferences[:github][:issue_links][0]).to eq(ENV['GITHUB_ISSUE_LINK'])

        # check sidebar counter increased to 1
        expect(find('.tabsSidebar-tab[data-tab=github] .js-tabCounter')).to have_text('1')

        # delete issue
        click(".sidebar-git-issue-delete span[data-issue-id='#{ENV['GITHUB_ISSUE_LINK']}']")
        await_empty_ajax_queue

        content = find('.sidebar[data-tab=github] .sidebar-content')
        expect(content).to have_text('No linked issues')
        expect(ticket.reload.preferences[:github][:issue_links][0]).to be nil

        # check that counter got removed
        expect(page).to have_no_selector('.tabsSidebar-tab[data-tab=github] .js-tabCounter')
      end
    end
  end

  context 'Sidebar - Open & Closed Tickets', searchindex: true, authenticated_as: :authenticate do
    let(:customer) { create(:customer, :with_org) }
    let(:ticket_open) { create(:ticket, group: Group.find_by(name: 'Users'), customer: customer, title: SecureRandom.uuid) }
    let(:ticket_closed) { create(:ticket, group: Group.find_by(name: 'Users'), customer: customer, state: Ticket::State.find_by(name: 'closed'), title: SecureRandom.uuid) }

    def authenticate
      ticket_open
      ticket_closed
      configure_elasticsearch(required: true, rebuild: true)
      Scheduler.worker(true)
      true
    end

    it 'does show open and closed tickets in advanced search url' do
      visit "#ticket/zoom/#{ticket_open.id}"
      click '.tabsSidebar-tab[data-tab=customer]'
      click '.user-tickets[data-type=open]'
      expect(page).to have_text(ticket_open.title, wait: 20)

      visit "#ticket/zoom/#{ticket_open.id}"
      click '.tabsSidebar-tab[data-tab=customer]'
      click '.user-tickets[data-type=closed]'
      expect(page).to have_text(ticket_closed.title, wait: 20)
    end
  end
end
