require 'rails_helper'

RSpec.describe 'Ticket zoom', type: :system do

  describe 'owner auto-assignment' do
    let!(:ticket) { create(:ticket, group: Group.find_by(name: 'Users'), state: Ticket::State.find_by(name: 'new')) }
    let!(:session_user) { User.find_by(login: 'master@example.com') }

    context 'for agent disabled' do
      before do
        Setting.set('ticket_auto_assignment', false)
        Setting.set('ticket_auto_assignment_selector', { condition: { 'ticket.state_id' => { operator: 'is', value: Ticket::State.by_category(:work_on).pluck(:id) } } })
        Setting.set('ticket_auto_assignment_user_ids_ignore', [])
      end

      it 'do not assign ticket to current session user' do
        refresh
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
      before do
        Setting.set('ticket_auto_assignment', true)
        Setting.set('ticket_auto_assignment_selector', { condition: { 'ticket.state_id' => { operator: 'is', value: Ticket::State.by_category(:work_on).pluck(:id) } } })
      end

      context 'with empty "ticket_auto_assignment_user_ids_ignore"' do
        it 'assigns ticket to current session user' do
          refresh
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
        it 'assigns ticket not to current session user' do
          Setting.set('ticket_auto_assignment_user_ids_ignore', session_user.id)

          refresh
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
        it 'assigns ticket not to current session user' do
          Setting.set('ticket_auto_assignment_user_ids_ignore', session_user.id.to_s)

          refresh
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
        it 'assigns ticket not to current session user' do
          Setting.set('ticket_auto_assignment_user_ids_ignore', [session_user.id])

          refresh
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
        it 'assigns ticket not to current session user' do
          Setting.set('ticket_auto_assignment_user_ids_ignore', [session_user.id.to_s])

          refresh
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
        it 'assigns ticket to current session user' do
          Setting.set('ticket_auto_assignment_user_ids_ignore', [99_999, 999_999])

          refresh
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
          find('.attachmentPlaceholder-label').in_fixed_postion
          expect(page).not_to have_css('.attachmentPlaceholder-hint', wait: 0)

          find('.articleNewEdit-body').send_keys('Some reply')
          click '.js-submit'

          expect(page).to have_css('.ticket-article-item', count: articles_expected)
        end
      end
    end
  end

  describe 'delete article', authenticated_as: :user do
    let(:admin)       { create :admin, groups: [Group.first] }
    let(:agent)       { create :agent, groups: [Group.first] }
    let(:other_agent) { create :agent, groups: [Group.first] }
    let(:customer)    { create :customer }
    let(:ticket)      { create :ticket, group: agent.groups.first, customer: customer }
    let(:article)     { send(item) }

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
      create(:ticket_article,
             sender_name: sender_name, internal: internal, type_name: type_name, ticket: ticket,
             body: "to be deleted #{offset} #{item}",
             updated_by_id: updated_by.id, created_by_id: updated_by.id,
             created_at: offset.ago, updated_at: offset.ago)
    end

    context 'going through full stack' do
      context 'as admin' do
        let(:user)   { admin }
        let(:item)   { 'article_note_self' }
        let(:offset) { 0.minutes }

        it 'succeeds' do
          refresh # make sure user roles are loaded

          ensure_websocket do
            visit "ticket/zoom/#{ticket.id}"
          end

          within :active_ticket_article, article, wait: 15 do
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
          let(:item) { item }
          let!(:article) {  send(item) }

          let(:offset) { offset }
          let(:matcher) { expects_visible ? :have_css : :have_no_css }

          it expects_visible ? 'delete button is visible' : 'delete button is not visible' do
            refresh # make sure user roles are loaded

            visit "ticket/zoom/#{ticket.id}"

            within :active_ticket_article, article, wait: 15 do
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
                         now: false, later: false, much_later: false

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
                         now: false, later: false, much_later: false

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
        before { Setting.set 'ui_ticket_zoom_article_delete_timeframe', 6000 }

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
        before { Setting.set 'ui_ticket_zoom_article_delete_timeframe', 0 }

        context 'as agent' do
          let(:user) { agent }

          include_examples 'according to permission matrix', item: 'article_note_self', expects_visible: true, offset: 99.days, description: 'long after'
        end
      end
    end

    context 'button is hidden on the go' do
      before         { Setting.set 'ui_ticket_zoom_article_delete_timeframe', 5 }

      let(:user)     { agent }
      let(:item)     { 'article_note_self' }
      let!(:article) { send(item) }
      let(:offset)   { 0.seconds }

      it 'successfully' do
        refresh # make sure user roles are loaded

        visit "ticket/zoom/#{ticket.id}"

        within :active_ticket_article, article do
          find '.js-ArticleAction[data-type=delete]' # make sure delete button did show up
          expect(page).to have_no_css('.js-ArticleAction[data-type=delete]', wait: 15)
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
          expect(page).not_to have_css('.article-content', text: 'somebody with some text')
          click '.js-securityRetryProcess'
          expect(page).to have_css('.article-content', text: 'somebody with some text')
        end
      end
    end

    context 'replying' do

      before do
        create(:ticket_article, ticket: ticket, from: customer.email)

        create(:smime_certificate, :with_private, fixture: system_email_address)
        create(:smime_certificate, fixture: sender_email_address)
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
end
