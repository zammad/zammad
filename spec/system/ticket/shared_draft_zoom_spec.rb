# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket Shared Draft Zoom', type: :system, authenticated_as: :authenticate do
  let(:group)               { create(:group, shared_drafts: group_shared_drafts) }
  let(:group_access)        { :full }
  let(:group_shared_drafts) { true }
  let(:ticket)              { create(:ticket, group: group) }
  let(:ticket_with_draft)   { create(:ticket, group: group) }
  let(:draft_body)          { 'draft here' }

  let(:draft) do
    create(:ticket_shared_draft_zoom,
           ticket:            ticket_with_draft,
           new_article:       { body: draft_body, type: 'note', internal: true },
           ticket_attributes: { priority_id: '3' })
  end

  let(:user) do
    user = create(:agent)
    user.user_groups.create! group: group, access: group_access
    user
  end

  def authenticate
    draft
    user
  end

  before do
    visit "ticket/zoom/#{ticket.id}"
  end

  shared_examples 'shared draft ID is present' do
    it 'sets shared draft ID' do
      within :active_content do
        elem = find('.article-add input[name=shared_draft_id]', visible: :all)

        expect(Ticket::SharedDraftZoom).to be_exist(elem.value)
      end
    end
  end

  context 'buttons' do
    context 'when drafts disabled for the group' do
      let(:group_shared_drafts) { false }

      it 'share button not visible' do
        expect(page).to have_no_selector :draft_share_button
      end

      it 'save button not visible' do
        click '.js-openDropdownMacro'

        expect(page).to have_no_selector :draft_save_button
      end
    end

    context 'when drafts enabled for the group' do
      it 'share button not visible initially' do
        expect(page).to have_no_selector :draft_share_button
      end

      it 'save button visible' do
        expect(page).to have_selector(:draft_save_button, visible: :all)
      end

      it 'share button visible when draft exists' do
        visit "ticket/zoom/#{ticket_with_draft.id}"

        within :active_content do
          expect(page).to have_selector :draft_share_button
        end
      end

      it 'share button appears when other user creates draft' do
        create(:ticket_shared_draft_zoom, ticket: ticket)

        expect(page).to have_selector :draft_share_button
      end
    end

    context 'when insufficient permissions' do
      let(:group_access) { :read }

      it 'share button not visible when draft exists' do
        visit "ticket/zoom/#{ticket_with_draft.id}"

        within :active_content do
          expect(page).to have_no_selector :draft_share_button
        end
      end

      it 'save button not visible' do
        click '.js-openDropdownMacro'

        expect(page).to have_no_selector :draft_save_button
      end
    end
  end

  context 'preview' do
    before do
      visit "ticket/zoom/#{ticket_with_draft.id}"

      within :active_content do
        click :draft_share_button
      end
    end

    it 'shows content' do
      in_modal disappears: false do
        expect(page).to have_text draft_body
      end
    end

    it 'shows author' do
      in_modal disappears: false do
        expect(page).to have_text(User.find(draft.created_by_id).fullname)
      end
    end
  end

  context 'delete' do
    it 'works' do
      visit "ticket/zoom/#{ticket_with_draft.id}"

      within :active_content do
        click :draft_share_button
      end

      in_modal do
        click '.js-delete'
      end

      click_on 'Yes'

      within :active_content do
        expect(page).to have_no_selector :draft_share_button
      end
    end

    it 'hides button when another user deletes' do
      visit "ticket/zoom/#{ticket_with_draft.id}"

      draft.destroy

      within :active_content do
        expect(page).to have_no_selector :draft_share_button
      end
    end
  end

  context 'save' do
    it 'creates new draft' do
      find('.articleNewEdit-body').send_keys('Some reply')

      click '.js-openDropdownMacro'

      expect { click :draft_save_button }
        .to change { ticket.reload.shared_draft.present? }
        .to true
    end

    it 'shows overwrite warning when draft exists' do
      visit "ticket/zoom/#{ticket_with_draft.id}"

      within :active_content do
        find('.articleNewEdit-body').send_keys('another reply')
        click '.js-openDropdownMacro'
        click :draft_save_button
      end

      in_modal do
        click '.js-submit'
      end

      expect(draft.reload.new_article[:body]).to match %r{another reply}
    end

    context 'draft saved' do
      before do
        find('.articleNewEdit-body').send_keys('Some reply')

        click '.js-openDropdownMacro'
        click :draft_save_button
      end

      include_examples 'shared draft ID is present'
    end

    context 'draft loaded' do
      before do
        visit "ticket/zoom/#{ticket_with_draft.id}"

        click :draft_share_button

        in_modal do
          click '.js-submit'
        end
      end

      it 'updates existing draft' do
        click '.js-openDropdownMacro'
        click :draft_save_button

        expect(draft.reload.new_article[:body]).to match %r{draft here}
      end

      it 'shows overwrite warning when draft edited after loading' do
        find('.articleNewEdit-body').send_keys('another reply')
        click '.js-openDropdownMacro'
        click :draft_save_button

        in_modal do
          click '.js-submit'
        end

        expect(draft.reload.new_article[:body]).to match %r{another reply}
      end
    end
  end

  context 'apply' do
    before do
      attach(id: draft.id, object_name: draft.class.name)

      visit "ticket/zoom/#{ticket_with_draft.id}"

      click :draft_share_button

      in_modal do
        click '.js-submit'
      end
    end

    include_examples 'shared draft ID is present'

    it 'applies new article body' do
      expect(page).to have_text draft_body
    end

    it 'applies sidebar changes' do
      expect(find('[name=priority_id]').value).to eq draft.ticket_attributes[:priority_id]
    end

    it 'applies attachment' do
      expect(page).to have_text('1x1.png')
    end
  end
end
