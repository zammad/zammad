# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'reply article' do |type_label:, internal:, attachments:|
  let(:group)             { Group.find_by(name: 'Users') }
  let(:agent)             { create(:agent, groups: [group]) }
  let(:customer)          { create(:customer) }
  let(:to)                { nil }
  let(:cc)                { nil }
  let(:trigger_label)     { 'Reply' }
  let(:has_text)          { '' }
  let(:new_text)          { 'This is a note' }

  before do
    article
  end

  # test only that reply works, because edge cases are covered by unit tests
  # rubocop:disable RSpec/ExampleLength
  it "can reply with #{type_label}" do
    visit "/tickets/#{ticket.id}"
    find_button('Article actions').click

    find_button(trigger_label).click

    expect(find_select('Article Type', visible: :all)).to have_selected_option(type_label)
    if internal
      expect(find_select('Visibility', visible: :all)).to have_selected_option('Internal')
    else
      expect(find_select('Visibility', visible: :all)).to have_selected_option('Public')
    end

    if article.from.present?
      expect(find_select('To', visible: :all)).to have_value(" #{article.from}")
    end

    if to.present?
      find_select('To').search_for_option(to)
    end

    if cc.present?
      find_select('CC').search_for_option(cc)
    end

    text = find_editor('Text')
    expect(text).to have_text_value(has_text, exact: true)
    text.type(new_text)

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
      type_id:     article.type_id,
      internal:    internal,
      body:        new_text,
      in_reply_to: article.message_id,
    }

    attributes[:to] = if to.present?
                        to
                      elsif article.from.present?
                        article.from
                      end

    attributes[:cc] = cc

    if attachments
      attributes[:attachments] = [Store.last]
      expect(Store.last.filename).to eq('small.png')
    end

    expect(Ticket::Article.last).to have_attributes(attributes)
  end
  # rubocop:enable RSpec/ExampleLength
end
