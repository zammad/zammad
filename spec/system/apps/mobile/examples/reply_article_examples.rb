# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'reply article' do |type_label, note, internal: false, attachments: false|
  let(:group)             { Group.find_by(name: 'Users') }
  let(:agent)             { create(:agent, groups: [group]) }
  let(:customer)          { create(:customer) }
  let(:to)                { nil }
  let(:new_to)            { nil }
  let(:trigger_label)     { 'Reply' }
  let(:current_text)      { '' }
  let(:new_text)          { 'This is a note' }
  let(:result_text)       { new_text || current_text }
  let(:in_reply_to)       { article.message_id }
  let(:type_id)           { article.type_id }

  before do
    article
  end

  # test only that reply works, because edge cases are covered by unit tests
  # rubocop:disable RSpec/ExampleLength
  it "can reply with #{type_label} #{note || ''}" do
    visit "/tickets/#{ticket.id}"
    find_button('Article actions').click

    find_button(trigger_label).click

    expect(find_select('Article Type', visible: :all)).to have_selected_option(type_label)
    expect(find_select('Visibility', visible: :all)).to have_selected_option(internal ? 'Internal' : 'Public')

    if to.present?
      expect(find_select('To', visible: :all)).to have_value(" #{to}")
    end

    text = find_editor('Text')
    expect(text).to have_text_value(current_text, exact: true)
    text.type(new_text) if new_text

    if new_to.present?
      find_select('To', visible: :all).search_for_option(new_to)
    end

    if attachments
      find_field('attachments', visible: :all).attach_file('spec/fixtures/files/image/small.png')

      # need to wait until the file is uploaded
      expect(page).to have_text('small.png', wait: 60)
    else
      expect(page).to have_no_field('attachments', visible: :all)
    end

    find_button('Done').click
    find_button('Save ticket').click

    wait_for_gql('apps/mobile/pages/ticket/graphql/mutations/update.graphql')

    attributes = {
      type_id:     type_id,
      internal:    internal,
      body:        result_text,
      in_reply_to: in_reply_to
    }

    if new_to.present?
      attributes[:to] = new_to
    elsif to.present?
      attributes[:to] = to
    end

    if attachments
      attributes[:attachments] = [Store.last]
      expect(Store.last.filename).to eq('small.png')
    end

    expect(Ticket::Article.last).to have_attributes(attributes)
  end
  # rubocop:enable RSpec/ExampleLength
end
