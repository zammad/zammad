# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'Ticket zoom > Highlighter', type: :system do
  let(:ticket)  { create(:ticket, group: Group.find_by(name: 'Users')) }
  let(:article) { create(:ticket_article, ticket: ticket, body: 'some highlighted text') }
  let(:other)   { create(:ticket_article, ticket: ticket, body: 'another marked text') }

  def highlight(article, color)
    article.preferences['highlight'] = "type:TextRange|0$4$1$highlight-#{color}$article-content-#{article.id}"
    article.save!
  end

  def expect_highlights
    expect(page).to have_css("#article-content-#{article.id} .highlight-Yellow", text: 'some')
      .and have_css("#article-content-#{other.id} .highlight-Green", text: 'anot')
  end

  before do
    highlight(article, 'Yellow')
    highlight(other, 'Green')
  end

  it 'shows stored highlights when a ticket is opened' do
    visit "#ticket/zoom/#{ticket.id}"

    expect_highlights
  end

  it 'shows stored highlights when a ticket is opened at an article' do
    visit "#ticket/zoom/#{ticket.id}/#{article.id}"

    expect_highlights
  end

  it 'shows stored highlights after a reload' do
    visit "#ticket/zoom/#{ticket.id}"
    expect(page).to have_css("#article-content-#{article.id}")
    refresh

    expect_highlights
  end

  it 'shows stored highlights after coming back to the ticket' do
    visit "#ticket/zoom/#{ticket.id}"
    expect(page).to have_css("#article-content-#{article.id}")
    visit 'dashboard'
    visit "#ticket/zoom/#{ticket.id}"

    expect_highlights
  end

  it 'keeps highlights when an article is rendered again' do
    visit "#ticket/zoom/#{ticket.id}"
    expect_highlights

    within "#article-#{article.id}" do
      click '.js-ArticleAction[data-type=internal]'
      expect(page).to have_css('.js-ArticleAction[data-type=public]')
    end

    expect_highlights
  end

  it 'shows stored highlights when a ticket loaded in the background is opened at an article' do
    visit "#ticket/zoom/#{ticket.id}"
    expect(page).to have_css("#article-content-#{article.id}")
    visit 'dashboard'
    refresh
    visit "#ticket/zoom/#{ticket.id}/#{article.id}"

    expect_highlights
  end

  it 'shows a new highlight after an immediate reload' do
    third = create(:ticket_article, ticket: ticket, body: 'third unmarked text')
    visit "#ticket/zoom/#{ticket.id}"
    expect(page).to have_css("#article-content-#{third.id}")
    page.execute_script("$('.js-highlight').first().trigger('click')")
    page.execute_script(<<~JS)
      var content = $('#article-content-#{third.id}');
      var text = document.createTreeWalker(content.find('.richtext-content')[0], NodeFilter.SHOW_TEXT).nextNode();
      var range = document.createRange();
      range.setStart(text, 0); range.setEnd(text, 5);
      var selection = window.getSelection(); selection.removeAllRanges(); selection.addRange(range);
      content.trigger('mousedown'); content.trigger('mouseup');
    JS
    expect(page).to have_css("#article-content-#{third.id} .highlight-Yellow", text: 'third')
    wait.until { third.reload.preferences['highlight'].present? }
    refresh

    expect(page).to have_css("#article-content-#{third.id} .highlight-Yellow", text: 'third')
    expect_highlights
  end
end
