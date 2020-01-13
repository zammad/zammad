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
end
