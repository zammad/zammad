# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket zoom > Add Link action', type: :system do
  describe 'ticket add link action' do
    context 'when source ticket is linked to target ticket' do
      let(:source_ticket) { create(:ticket, group: Group.find_by(name: 'Users')) }
      let(:target_ticket) { create(:ticket, group: Group.find_by(name: 'Users')) }
      let(:ticket_number) { target_ticket.number }

      before do
        visit "#ticket/zoom/#{source_ticket.id}"
      end

      shared_examples 'adding link to target ticket' do
        it 'adds link to target ticket' do
          click('.js-add', text: 'Add Link')

          in_modal do
            fill_in 'ticket_number', with: ticket_number

            # Trigger the paste event to replace the ticket hook, if present.
            execute_script('$("input[name=\"ticket_number\"]").trigger("paste")')

            click '.js-submit'
          end

          await_empty_ajax_queue

          added_link = Link.list(link_object: 'Ticket', link_object_value: source_ticket.id).last
          expect(added_link).to eq({
                                     'link_object'       => 'Ticket',
                                     'link_object_value' => target_ticket.id,
                                     'link_type'         => 'normal',
                                   })
        end
      end

      context 'when input field is used without ticket hook' do
        it_behaves_like 'adding link to target ticket'
      end

      context 'when input field is used with ticket hook' do
        let(:search_term) { Setting.get('ticket_hook') + target_ticket.number }

        it_behaves_like 'adding link to target ticket'
      end
    end
  end
end
