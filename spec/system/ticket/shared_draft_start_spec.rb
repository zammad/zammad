# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket Shared Draft Start', authenticated_as: :authenticate, type: :system do
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
    visit '/'
    click '.settings.add'
  end

  shared_examples 'shared draft ID is present' do
    it 'sets shared draft ID' do
      within :active_content do
        elem = find('.ticket-create input[name=shared_draft_id]', visible: :all)

        expect(Ticket::SharedDraftStart).to be_exist(elem.value)
      end
    end
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
          .to change(Ticket::SharedDraftStart, :count)
          .by 1
      end
    end

    context 'with a signature' do
      let(:signature) { create(:signature) }
      let(:group)     { create(:group, shared_drafts: group_shared_drafts, signature: signature) }

      # https://github.com/zammad/zammad/issues/4042
      it 'creates a draft without signature' do
        within :active_content do
          find('div[data-name=body]').send_keys draft_body
          find('[data-type=email-out]').click
        end

        within :draft_sidebar do
          find('.js-name').fill_in with: 'Draft Name'
          click '.js-create'
        end

        wait.until do
          draft = Ticket::SharedDraftStart.last

          next false if draft.nil?

          expect(draft.content).to include(body: draft_body)
        end
      end
    end

    context 'draft saved' do
      before do
        within :draft_sidebar do
          find('.js-name').fill_in with: 'Draft Name'

          click '.js-create'
        end
      end

      include_examples 'shared draft ID is present'
    end
  end

  context 'update' do
    before do
      create(:store, :image, o_id: draft.id, object: draft.class.name)
      click :draft_sidebar_button

      within :draft_sidebar do
        click '.text-muted'
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
          .to change(Ticket::SharedDraftStart, :count)
          .by 1
      end
    end
  end

  context 'delete' do
    it 'works as expected' do
      click :draft_sidebar_button

      within :draft_sidebar do
        click '.text-muted'
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
        click '.text-muted'
      end
    end

    it 'shows body' do
      in_modal do
        expect(page).to have_text(draft_body)
      end
    end

    it 'shows author' do
      in_modal do
        expect(page).to have_text(User.find(draft.created_by_id).fullname)
      end
    end
  end

  context 'apply' do
    before do
      create(:store, :image, o_id: draft.id, object: draft.class.name)
      click :draft_sidebar_button

      within :draft_sidebar do
        click '.text-muted'
      end

      in_modal do
        click '.js-submit'
      end
    end

    include_examples 'shared draft ID is present'

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

    context 'with a signature' do
      let(:signature_body) { 'Sample signature here' }
      let(:signature)      { create(:signature, body: signature_body) }
      let(:group)          { create(:group, shared_drafts: group_shared_drafts, signature: signature) }
      let(:draft_options)  { { priority_id: '3', formSenderType: 'email-out' } }

      # https://github.com/zammad/zammad/issues/4042
      it 'applies with a signature' do
        within :active_content do
          expect(page).to have_text(signature_body).and(have_text(draft_body))
        end
      end
    end
  end
end
