# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

RSpec.shared_examples 'reply article' do |type_label, note, internal: false, attachments: false|
  let(:attributes) do
    attributes = {
      type_id:     type_id,
      internal:    internal,
      body:        result_text,
      in_reply_to: in_reply_to
    }

    saved_to = result_to if result_to.present?
    saved_to = saved_to.join(', ') if saved_to.is_a?(Array)

    saved_cc = cc if cc.present?
    saved_cc = saved_cc.join(', ') if saved_cc.is_a?(Array)

    saved_subject = article_subject if article_subject.present?
    saved_subject = new_subject if new_subject.present?

    attributes[:to] = saved_to if saved_to.present?
    attributes[:cc] = saved_cc if cc.present?
    attributes[:subject] = saved_subject if saved_subject.present?

    attributes
  end

  before do
    article

    visit "/tickets/#{ticket.id}"

    wait_for_gql('apps/mobile/pages/ticket/graphql/queries/ticket/articles.graphql')
    wait_for_form_to_settle('form-ticket-edit')
    before_click.call

    find_button('Article actions').click
    find_button(trigger_label).click
  end

  # test only that reply works, because edge cases are covered by unit tests
  it "can reply with #{type_label} #{note || ''}" do
    after_click.call

    expect(find_select('Article Type', visible: :all)).to have_selected_option(type_label)
    expect(find_select('Visibility', visible: :all)).to have_selected_option(internal ? 'Internal' : 'Public')

    expect(find_autocomplete('To')).to have_selected_options(to) if to.present?
    expect(find_autocomplete('CC')).to have_selected_options(cc) if cc.present?
    expect(find_select('Subject', visible: :all)).to have_value(article_subject) if article_subject.present?

    text = find_editor('Text')
    expect(text).to have_text_value(current_text, exact: text_exact)
    text.type(new_text, click: false) if new_text

    find_autocomplete('To').search_for_option(new_to) if new_to.present?
    find_field('Subject', visible: :all).input(new_subject) if new_subject.present?

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

    if attachments
      attributes[:attachments] = result_attachments
      expect(Store.last.filename).to eq('small.png')
    end

    expect(Ticket::Article.last).to have_attributes(attributes)
  end
end
