# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket zoom > Article actions', type: :system do
  describe 'delete article', authenticated_as: :authenticate do
    let(:group)       { Group.first }
    let(:admin)       { create(:admin, groups: [group]) }
    let(:agent)       { create(:agent, groups: [group]) }
    let(:other_agent) { create(:agent, groups: [group]) }
    let(:customer)    { create(:customer) }
    let(:article)     { send(item) }

    def authenticate
      Setting.set('ui_ticket_zoom_article_delete_timeframe', setting_delete_timeframe) if defined?(setting_delete_timeframe)
      article
      user
    end

    def article_communication
      create_ticket_article(sender_name: 'Agent', internal: false, type_name: 'email', updated_by: customer)
    end

    def article_note_self
      create_ticket_article(sender_name: 'Agent', internal: true, type_name: 'note', updated_by: user)
    end

    def article_note_other
      create_ticket_article(sender_name: 'Agent', internal: true, type_name: 'note', updated_by: other_agent)
    end

    def article_note_customer
      create_ticket_article(sender_name: 'Customer', internal: false, type_name: 'note', updated_by: customer)
    end

    def article_note_communication_self
      create(:ticket_article_type, name: 'note_communication', communication: true)

      create_ticket_article(sender_name: 'Agent', internal: true, type_name: 'note_communication', updated_by: user)
    end

    def article_note_communication_other
      create(:ticket_article_type, name: 'note_communication', communication: true)

      create_ticket_article(sender_name: 'Agent', internal: true, type_name: 'note_communication', updated_by: other_agent)
    end

    def create_ticket_article(sender_name:, internal:, type_name:, updated_by:)
      UserInfo.current_user_id = updated_by.id

      ticket = create(:ticket, group: group, customer: customer)

      create(:ticket_article,
             sender_name: sender_name, internal: internal, type_name: type_name, ticket: ticket,
             body: "to be deleted #{offset} #{item}",
             created_at: offset.ago, updated_at: offset.ago)
    end

    context 'going through full stack' do
      context 'as admin' do
        let(:user)   { admin }
        let(:item)   { 'article_note_self' }
        let(:offset) { 0.minutes }

        it 'succeeds' do
          ensure_websocket do
            visit "ticket/zoom/#{article.ticket.id}"
          end

          within :active_ticket_article, article do
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
          let(:item)    { item }
          let(:offset)  { offset }
          let(:matcher) { expects_visible ? :have_css : :have_no_css }

          it expects_visible ? 'delete button is visible' : 'delete button is not visible' do
            visit "ticket/zoom/#{article.ticket.id}"

            find("#article-#{article.id}")

            within :active_ticket_article, article do
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
        let(:user) { admin }

        include_examples 'deleting ticket article',
                         item: 'article_communication',
                         now: false, later: false, much_later: false

        include_examples 'deleting ticket article',
                         item: 'article_note_self',
                         now: true, later: true, much_later: false

        include_examples 'deleting ticket article',
                         item: 'article_note_other',
                         now: false, later: false, much_later: false

        include_examples 'deleting ticket article',
                         item: 'article_note_customer',
                         now: false, later: false, much_later: false

        include_examples 'deleting ticket article',
                         item: 'article_note_communication_self',
                         now: true, later: true, much_later: false

        include_examples 'deleting ticket article',
                         item: 'article_note_communication_other',
                         now: false, later: false, much_later: false
      end

      context 'as agent' do
        let(:user) { agent }

        include_examples 'deleting ticket article',
                         item: 'article_communication',
                         now: false, later: false, much_later: false

        include_examples 'deleting ticket article',
                         item: 'article_note_self',
                         now: true, later: true, much_later: false

        include_examples 'deleting ticket article',
                         item: 'article_note_other',
                         now: false, later: false, much_later: false

        include_examples 'deleting ticket article',
                         item: 'article_note_customer',
                         now: false, later: false, much_later: false

        include_examples 'deleting ticket article',
                         item: 'article_note_communication_self',
                         now: true, later: true, much_later: false

        include_examples 'deleting ticket article',
                         item: 'article_note_communication_other',
                         now: false, later: false, much_later: false
      end

      context 'as customer' do
        let(:user) { customer }

        include_examples 'deleting ticket article',
                         item: 'article_communication',
                         now: false, later: false, much_later: false

        include_examples 'deleting ticket article',
                         item: 'article_note_customer',
                         now: false, later: false, much_later: false

      end

      context 'with custom offset' do
        let(:setting_delete_timeframe) { 6_000 }

        context 'as admin' do
          let(:user) { admin }

          include_examples 'according to permission matrix', item: 'article_note_self', expects_visible: true,  offset: 5000.seconds, description: 'outside of delete timeframe'
          include_examples 'according to permission matrix', item: 'article_note_self', expects_visible: false, offset: 8000.seconds, description: 'outside of delete timeframe'
        end

        context 'as agent' do
          let(:user) { agent }

          include_examples 'according to permission matrix', item: 'article_note_self', expects_visible: true,  offset: 5000.seconds, description: 'outside of delete timeframe'
          include_examples 'according to permission matrix', item: 'article_note_self', expects_visible: false, offset: 8000.seconds, description: 'outside of delete timeframe'
        end
      end

      context 'with timeframe as 0' do
        let(:setting_delete_timeframe) { 0 }

        context 'as agent' do
          let(:user) { agent }

          include_examples 'according to permission matrix', item: 'article_note_self', expects_visible: true, offset: 99.days, description: 'long after'
        end
      end
    end

    context 'button is hidden on the go' do
      let(:setting_delete_timeframe) { 10 }

      let(:user)     { agent }
      let(:item)     { 'article_note_self' }
      let!(:article) { send(item) }
      let(:offset)   { 0.seconds }

      it 'successfully' do
        visit "ticket/zoom/#{article.ticket.id}"

        within :active_ticket_article, article do
          find '.js-ArticleAction[data-type=delete]' # make sure delete button did show up
          expect(page).to have_no_css('.js-ArticleAction[data-type=delete]')
        end
      end
    end
  end

  describe 'forwarding article with an image' do
    let(:ticket_article_body) do
      filename = 'squares.png'
      file     = Rails.root.join("spec/fixtures/files/image/#{filename}").binread
      ext      = File.extname(filename)[1...]
      base64   = Base64.encode64(file).delete("\n")

      "<img style='width: 1004px; max-width: 100%;' src=\"data:image/#{ext};base64,#{base64}\"><br>"
    end

    def current_ticket
      Ticket.find current_url.split('/').last
    end

    def create_ticket
      visit '#ticket/create'

      within :active_content do
        find('[data-type=email-out]').click

        find('[name=title]').fill_in with: 'Title'
        find('[name=customer_id_completion]').fill_in with: 'customer@example.com'
        set_tree_select_value('group_id', Group.first.name)
        set_editor_field_richtext_value('body', ticket_article_body)
        find('.js-submit').click
      end
    end

    def forward
      within :active_content do
        find('.textBubble-content .richtext-content')
        click '.js-ArticleAction[data-type=emailForward]'
        fill_in 'To', with: 'customer@example.com'
        find('.js-submit').click
      end
    end

    def images_identical?(image_a, image_b)
      return false if image_a.height != image_b.height
      return false if image_a.width != image_b.width

      image_a.height.times do |y|
        image_a.row(y).each_with_index do |pixel, x|
          return false if pixel != image_b[x, y]
        end
      end

      true
    end

    it 'keeps image intact' do
      create_ticket
      forward

      images = current_ticket.articles.map do |article|
        ChunkyPNG::Image.from_string article.attachments.first.content
      end

      expect(images_identical?(images.first, images.second)).to be(true)
    end
  end

  describe 'Article ID URL / link' do
    let(:ticket)   { create(:ticket, group: Group.first) }
    let!(:article) { create(:'ticket/article', ticket: ticket) }

    it 'shows Article direct link' do
      ensure_websocket do
        visit "ticket/zoom/#{ticket.id}"
      end

      url = "#{Setting.get('http_type')}://#{Setting.get('fqdn')}/#ticket/zoom/#{ticket.id}/#{article.id}"

      within :active_ticket_article, article do
        expect(page).to have_css(%(a[href="#{url}"]))
      end
    end

    context 'when multiple Articles are present' do
      let(:article_count) { 20 }
      let(:article_top)    { ticket.articles.second }
      let(:article_middle) { ticket.articles[ article_count / 2 ] }
      let(:article_bottom) { ticket.articles.last }

      before do
        article_count.times do
          create(:'ticket/article', ticket: ticket, body: SecureRandom.uuid)
        end

        visit "ticket/zoom/#{ticket.id}"
      end

      def wait_for_scroll
        wait(5, interval: 0.2).until_constant do
          find('.ticketZoom').native.location.y
        end
      end

      def check_shown(top: false, middle: false, bottom: false)
        wait_for_scroll

        expect(page).to have_css("div#article-content-#{article_top.id} .richtext-content", obscured: !top)
          .and(have_css("div#article-content-#{article_middle.id} .richtext-content", obscured: !middle, wait: 0))
          .and(have_css("div#article-content-#{article_bottom.id} .richtext-content", obscured: !bottom, wait: 0))
      end

      it 'scrolls to top article ID' do
        visit "ticket/zoom/#{ticket.id}/#{article_top.id}"
        check_shown(top: true)
      end

      it 'scrolls to middle article ID' do
        visit "ticket/zoom/#{ticket.id}/#{article_middle.id}"
        check_shown(middle: true)
      end

      it 'scrolls to bottom article ID' do
        visit "ticket/zoom/#{ticket.id}/#{article_top.id}"
        wait_for_scroll

        visit "ticket/zoom/#{ticket.id}/#{article_bottom.id}"
        check_shown(bottom: true)
      end
    end

    context 'when long articles are present' do
      it 'shows the "See more" link if you switch between the ticket and the dashboard on new articles' do
        ensure_websocket do
          # prerender ticket
          visit "ticket/zoom/#{ticket.id}"

          # ticket tab becomes background
          visit 'dashboard'
        end

        # create a new article
        article_id = create(:'ticket/article', ticket: ticket, body: "#{SecureRandom.uuid} #{"lorem ipsum\n" * 200}")

        wait(30).until { has_css?('div.tasks a.is-modified') }

        visit "ticket/zoom/#{ticket.id}"

        within :active_content do
          expect(find("div#article-content-#{article_id.id}")).to have_text('See more')
        end
      end
    end
  end

  describe 'Image preview #4044' do
    let(:ticket) { create(:ticket, group: Group.find_by(name: 'Users')) }

    let(:image_as_base64) do
      file = Rails.root.join('spec/fixtures/files/image/squares.png').binread
      Base64.encode64(file).delete("\n")
    end

    let(:body) do
      "<img style='width: 1004px; max-width: 100%;' src='data:image/png;base64,#{image_as_base64}'><br>"
    end

    let(:article) { create(:ticket_article, ticket: ticket, body: body, content_type: 'text/html') }

    before do
      visit "#ticket/zoom/#{article.ticket.id}"
    end

    it 'does open the image preview for a common image' do
      within :active_ticket_article, article do
        find('img').click
      end

      in_modal do
        expect(page).to have_css('div.imagePreview img')
        expect(page).to have_css('.js-cancel')
        expect(page).to have_css('.js-submit')

        page.find('.js-cancel').click
      end
    end

    context 'with image and embedded link' do
      let(:body) do
        "<a href='https://zammad.com' title='Zammad' target='_blank'>
<img style='width: 1004px; max-width: 100%;' src='data:image/png;base64,#{image_as_base64}'>
</a><br>"
      end

      it 'does open the link for an image with an embedded link' do
        within :active_ticket_article, article do
          find('img').click
        end

        within_window switch_to_window_index(2) do
          expect(page).to have_link(class: ['logo'])
        end
        close_window_index(2)
      end
    end
  end

  describe 'Copying ticket number' do
    let(:ticket) { create(:ticket, group: Group.find_by(name: 'Users')) }
    let(:ticket_number_copy_element) { 'span.ticket-number-copy svg.ticketNumberCopy-icon' }
    let(:expected_clipboard_content) { (Setting.get('ticket_hook') + ticket.number).to_s }
    let(:field)                      { find(:richtext) }

    before do
      visit "#ticket/zoom/#{ticket.id}"
    end

    it 'copies the ticket number correctly' do
      find(ticket_number_copy_element).click

      # simulate a paste action
      within(:active_content) do
        field.send_keys('')
        field.click
        field.send_keys([magic_key, 'v'])
      end

      expect(field.text).to eq(expected_clipboard_content)
    end
  end

  describe 'Article update causes missing icons in the UI after switching internal state #4213' do
    let(:ticket)  { create(:ticket, group: Group.find_by(name: 'Users')) }
    let(:article) { create(:ticket_article, ticket: ticket, body: SecureRandom.uuid) }

    before do
      visit "#ticket/zoom/#{article.ticket.id}"
    end

    it 'does find the ticket by ticket number' do
      expect(page).to have_text(article.body)
      article.update(body: SecureRandom.uuid)
      expect(page).to have_text(article.body)
      click '.js-ArticleAction[data-type=internal]'
      click '.js-ArticleAction[data-type=public]'
      expect(page).to have_css('.js-ArticleAction[data-type=emailReply]')
    end
  end
end
