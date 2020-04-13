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
      let(:current_user) { create(:agent_user, password: 'test', groups: [ticket.group]) }

      before do
        # initial article to reply to
        create(:ticket_article, ticket: ticket)
      end

      it 'ensures that text input opens on multiple replies', authenticated: -> { current_user } do
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

  describe 'delete article', authenticated: -> { user } do
    let(:admin_user)    { create :admin, groups: [Group.first] }
    let(:agent_user)    { create :agent, groups: [Group.first] }
    let(:customer_user) { create :customer }
    let(:ticket)        { create :ticket, group: agent_user.groups.first, customer: customer_user }
    let(:article)       { send(item) }

    def article_communication
      create_ticket_article(sender_name: 'Agent', internal: false, type_name: 'email', updated_by: customer_user)
    end

    def article_note
      create_ticket_article(sender_name: 'Agent', internal: true, type_name: 'note', updated_by: agent_user)
    end

    def article_note_customer
      create_ticket_article(sender_name: 'Customer', internal: false, type_name: 'note', updated_by: customer_user)
    end

    def article_note_communication
      create(:ticket_article_type, name: 'note_communication', communication: true)

      create_ticket_article(sender_name: 'Agent', internal: true, type_name: 'note_communication', updated_by: agent_user)
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
        let(:user)   { admin_user }
        let(:item)   { 'article_communication' }
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
        let(:user) { admin_user }

        include_examples 'deleting ticket article',
                         item: 'article_communication',
                         now: true, later: true, much_later: true

        include_examples 'deleting ticket article',
                         item: 'article_note',
                         now: true, later: true, much_later: true

        include_examples 'deleting ticket article',
                         item: 'article_note_customer',
                         now: true, later: true, much_later: true

        include_examples 'deleting ticket article',
                         item: 'article_note_communication',
                         now: true, later: true, much_later: true
      end

      context 'as agent' do
        let(:user) { agent_user }

        include_examples 'deleting ticket article',
                         item: 'article_communication',
                         now: false, later: false, much_later: false

        include_examples 'deleting ticket article',
                         item: 'article_note',
                         now: true, later: true, much_later: false

        include_examples 'deleting ticket article',
                         item: 'article_note_customer',
                         now: false, later: false, much_later: false

        include_examples 'deleting ticket article',
                         item: 'article_note_communication',
                         now: true, later: true, much_later: false
      end

      context 'as customer' do
        let(:user) { customer_user }

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
          let(:user) { admin_user }

          include_examples 'according to permission matrix', item: 'article_note', expects_visible: true, offset: 8000.seconds, description: 'outside of delete timeframe'
        end

        context 'as agent' do
          let(:user) { agent_user }

          include_examples 'according to permission matrix', item: 'article_note', expects_visible: true,  offset: 5000.seconds, description: 'outside of delete timeframe'
          include_examples 'according to permission matrix', item: 'article_note', expects_visible: false, offset: 8000.seconds, description: 'outside of delete timeframe'
        end
      end

      context 'with timeframe as 0' do
        before { Setting.set 'ui_ticket_zoom_article_delete_timeframe', 0 }

        context 'as agent' do
          let(:user) { agent_user }

          include_examples 'according to permission matrix', item: 'article_note', expects_visible: true, offset: 99.days, description: 'long after'
        end
      end
    end

    context 'button is hidden on the go' do
      before         { Setting.set 'ui_ticket_zoom_article_delete_timeframe', 5 }

      let(:user)     { agent_user }
      let(:item)     { 'article_note' }
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
end
