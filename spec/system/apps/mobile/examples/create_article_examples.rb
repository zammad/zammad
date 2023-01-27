# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'create article' do |type_label, internal: false, attachments: false, conditional: true|
  let(:group)     { Group.find_by(name: 'Users') }
  let(:agent)     { create(:agent, groups: [group]) }
  let(:customer)  { create(:customer) }
  let(:to)        { '' }
  let(:cc)        { '' }

  # expected variables:
  # ticket
  # type as object

  def open_article_dialog
    visit "/tickets/#{ticket.id}"
    find_button('Add reply').click
  end

  def save_article
    find_button('Done').click
    find_button('Save ticket').click

    wait_for_gql('apps/mobile/pages/ticket/graphql/mutations/update.graphql')
  end

  context 'when ticket was not created as the same type', if: conditional do
    before do
      if type.name == 'note'
        create(:ticket_article, :inbound_email, ticket: ticket)
      else
        create(:ticket_article, ticket: ticket, type_name: 'note')
      end
    end

    it 'cannot create article' do
      open_article_dialog

      expect(find_select('Article Type', visible: :all).open.dialog_element).to have_no_text(type_label)
    end
  end

  context 'when ticket was created as the same type' do
    before do
      article
    end

    it "can create article #{type_label}" do
      open_article_dialog

      find_select('Article Type', visible: :all).select_option(type_label)

      if internal
        expect(find_select('Visibility', visible: :all)).to have_selected_option('Internal')
      else
        expect(find_select('Visibility', visible: :all)).to have_selected_option('Public')
      end

      text = find_editor('Text')
      expect(text).to have_text_value('', exact: true)
      text.type('This is a note')

      # TODO: when to and cc is fixed, enable this, + add check in attributes
      # if to.present?
      #   find_field('To', visible: :all).search_for_option(to)
      # end

      # if cc.present?
      #   find_field('CC', visible: :all).search_for_option(cc)
      # end

      if attachments
        find_field('attachments', visible: :all).attach_file('spec/fixtures/files/image/small.png')

        # need to wait until the file is uploaded
        expect(page).to have_text('small.png', wait: 60)
      else
        expect(page).to have_no_field('attachments', visible: :all)
      end

      save_article

      attributes = {
        type_id:      type.id,
        internal:     internal,
        content_type: content_type,
      }

      attributes[:body] = content_type == 'text/html' ? '<p>This is a note</p>' : 'This is a note'

      if attachments
        attributes[:attachments] = [Store.last]
        expect(Store.last.filename).to eq('small.png')
      end

      expect(Ticket::Article.last).to have_attributes(attributes)
    end
  end
end
