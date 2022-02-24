# Copyright (C) 2012-2022 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket Shared Draft Start', type: :system, authenticated_as: :authenticate do
  let(:group)               { create(:group, shared_drafts: group_shared_drafts) }
  let(:group_access)        { :full }
  let(:group_shared_drafts) { true }
  let(:draft)               { create(:ticket_shared_draft_start, group: group, content: draft_content) }
  let(:draft_body)          { 'draft body' }
  let(:draft_options)       { { priority_id: '3' } }

  let(:draft_content) do
    {
      body: draft_body
    }.merge draft_options
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
    click '.settings.add'
  end

  context 'sidebar' do
    context 'given multiple groups' do
      let(:another_group) { create(:group, shared_drafts: false) }

      def authenticate
        user.user_groups.create! group: another_group, access: :full
        user
      end

      it 'not visible without group selected' do
        expect(page).to have_no_selector :draft_sidebar_button
      end

      it 'not visible when group with disabled draft selected' do
        within(:active_content) do
          select another_group.name, from: 'group_id'
        end

        expect(page).to have_no_selector :draft_sidebar_button
      end

      it 'visible when group with active draft selected' do
        within(:active_content) do
          select group.name, from: 'group_id'
        end

        expect(page).to have_selector :draft_sidebar_button
      end
    end

    context 'when single group' do
      it 'visible' do
        expect(page).to have_selector :draft_sidebar_button
      end

      context 'when drafts disabled' do
        let(:group_shared_drafts) { false }

        it 'not visible' do
          expect(page).to have_no_selector :draft_sidebar_button
        end
      end
    end
  end

  context 'create' do
    before { click :draft_sidebar_button }

    it 'prevents a draft creation without name' do
      within :draft_sidebar do
        expect { click '.js-create' }
          .to change { has_css? '.has-error', wait: false }
          .to true
      end
    end

    it 'create a draft with name' do
      within :draft_sidebar do
        find('.js-name').fill_in with: 'Draft Name'

        expect { click '.js-create' }
          .to change { Ticket::SharedDraftStart.count }
          .by 1
      end
    end
  end

  context 'update' do
    before do
      attach(id: draft.id, object_name: draft.class.name)
      click :draft_sidebar_button

      within :draft_sidebar do
        click '.label-subtle'
      end

      in_modal do
        click '.js-submit'
      end
    end

    it 'changes content' do
      within :active_content do
        find(:richtext).send_keys('add update')
        click '.js-update'
      end

      expect(draft.reload.content['body']).to match %r{add update}
    end

    it 'changes name' do
      within :active_content do
        find('.js-name').fill_in with: 'new name'
        click '.js-update'
      end

      expect(draft.reload.name).to eq 'new name'
    end

    it 'requires name' do
      within :draft_sidebar do
        find('.js-name').fill_in with: ''

        expect { click '.js-update' }
          .to change { has_css? '.has-error', wait: false }
          .to true
      end
    end

    it 'saves as copy' do
      within :draft_sidebar do
        expect { click '.js-create' }
          .to change { Ticket::SharedDraftStart.count }
          .by 1
      end
    end
  end

  context 'delete' do
    it 'works' do
      click :draft_sidebar_button

      within :draft_sidebar do
        click '.label-subtle'
      end

      in_modal do
        click '.js-delete'
      end

      click_on 'Yes'

      expect(Ticket::SharedDraftStart).not_to be_exist(draft.id)

      within :draft_sidebar do
        expect(page).to have_no_text(draft.name)
      end
    end
  end

  context 'preview' do
    before do
      click :draft_sidebar_button

      within :draft_sidebar do
        click '.label-subtle'
      end
    end

    it 'shows body' do
      in_modal disappears: false do
        expect(page).to have_text(draft_body)
      end
    end

    it 'shows author' do
      in_modal disappears: false do
        expect(page).to have_text(User.find(draft.created_by_id).fullname)
      end
    end
  end

  context 'apply' do
    before do
      attach(id: draft.id, object_name: draft.class.name)
      click :draft_sidebar_button

      within :draft_sidebar do
        click '.label-subtle'
      end

      in_modal do
        click '.js-submit'
      end
    end

    it 'applies body' do
      within :active_content do
        expect(page).to have_text draft_body
      end
    end

    it 'applies meta' do
      within :active_content do
        expect(find('[name=priority_id]').value).to eq draft_options[:priority_id]
      end
    end

    it 'applies attachment' do
      within :active_content do
        expect(page).to have_text('1x1.png')
      end
    end
  end

  def attach(id:, object_name: 'UploadCache')
    Store.add(
      object:        object_name,
      o_id:          id,
      data:          File.binread(Rails.root.join('test/data/image/1x1.png')),
      filename:      '1x1.png',
      preferences:   {},
      created_by_id: 1,
    )
  end
end
