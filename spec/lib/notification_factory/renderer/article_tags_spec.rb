# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'rails_helper'

RSpec.describe 'NotificationFactory::Renderer article tags' do # rubocop:disable RSpec/DescribeClass
  let(:ticket) do
    ticket = create(:ticket)
    create(
      :ticket_article,
      type:         Ticket::Article::Type.lookup(name: 'note'),
      sender:       Ticket::Article::Sender.lookup(name: 'System'),
      body:         'Welcome to Zammad!',
      content_type: 'text/plain',
      ticket_id:    ticket.id,
    )
    create(
      :ticket_article,
      type:         Ticket::Article::Type.lookup(name: 'note'),
      sender:       Ticket::Article::Sender.lookup(name: 'Customer'),
      body:         'Thank you!',
      content_type: 'text/plain',
      ticket_id:    ticket.id,
    )
    create(
      :ticket_article,
      type:         Ticket::Article::Type.lookup(name: 'note'),
      sender:       Ticket::Article::Sender.lookup(name: 'System'),
      body:         'Received reply.',
      content_type: 'text/plain',
      internal:     true,
      ticket_id:    ticket.id,
    )

    ticket
  end

  let(:article) { nil }

  let(:objects) do
    last_article = nil
    last_internal_article = nil
    last_external_article = nil
    all_articles = ticket.articles

    if article.nil?
      last_article = all_articles.last
      last_internal_article = all_articles.reverse.find(&:internal?)
      last_external_article = all_articles.reverse.find { |a| !a.internal? }
    else
      last_article = article
      last_internal_article = article.internal? ? article : all_articles.reverse.find(&:internal?)
      last_external_article = article.internal? ? all_articles.reverse.find { |a| !a.internal? } : article
    end

    {
      ticket:                   ticket,
      article:                  last_article,
      last_article:             last_article,
      last_internal_article:    last_internal_article,
      last_external_article:    last_external_article,
      created_article:          article,
      created_internal_article: article&.internal? ? article : nil,
      created_external_article: article&.internal? ? nil : article,
    }
  end
  let(:renderer) do
    build(:notification_factory_renderer,
          objects:  objects,
          template: template)
  end

  describe 'last_article' do
    let(:template) { "\#{last_article.body}" }

    it 'has body content from the last article' do
      expect(renderer.render).to eq "&gt; #{ticket.articles.last.body}<br>"
    end
  end

  describe 'last_internal_article' do
    let(:template) { "\#{last_internal_article.body}" }

    it 'has body content from the last article' do
      expect(renderer.render).to eq "&gt; #{ticket.articles.last.body}<br>"
    end
  end

  describe 'last_external_article' do
    let(:template) { "\#{last_external_article.body}" }

    it 'has body content from the third article' do
      expect(renderer.render).to eq "&gt; #{ticket.articles.second.body}<br>"
    end
  end

  describe 'created_article' do
    let(:template) { "\#{created_article.body}" }

    it 'no such object' do
      expect(renderer.render).to eq '#{created_article / no such object}' # rubocop:disable Lint/InterpolationCheck
    end
  end

  describe 'created_internal_article' do
    let(:template) { "\#{created_internal_article.body}" }

    it 'no such object' do
      expect(renderer.render).to eq '#{created_internal_article / no such object}' # rubocop:disable Lint/InterpolationCheck
    end
  end

  describe 'created_external_article' do
    let(:template) { "\#{created_external_article.body}" }

    it 'no such object' do
      expect(renderer.render).to eq '#{created_external_article / no such object}' # rubocop:disable Lint/InterpolationCheck
    end
  end

  context 'when creating a new internal article' do
    let(:article) do
      create(
        :ticket_article,
        type:         Ticket::Article::Type.lookup(name: 'note'),
        sender:       Ticket::Article::Sender.lookup(name: 'Agent'),
        body:         'Nice dude!',
        content_type: 'text/plain',
        internal:     true,
        ticket_id:    ticket.id,
      )
    end

    describe 'created_article' do
      let(:template) { "\#{created_article.body}" }

      it 'has body content from the new article' do
        expect(renderer.render).to eq "&gt; #{ticket.articles.last.body}<br>"
      end
    end

    describe 'created_internal_article' do
      let(:template) { "\#{created_internal_article.body}" }

      it 'has body content from the new article' do
        expect(renderer.render).to eq "&gt; #{ticket.articles.last.body}<br>"
      end
    end

    describe 'created_external_article' do
      let(:template) { "\#{created_external_article.body}" }

      it 'no such object' do
        expect(renderer.render).to eq '#{created_external_article / no such object}' # rubocop:disable Lint/InterpolationCheck
      end
    end

    describe 'last_article' do
      let(:template) { "\#{last_article.body}" }

      it 'has body content from the last article' do
        expect(renderer.render).to eq "&gt; #{ticket.articles.last.body}<br>"
      end
    end

    context 'when setting new article external' do
      before do
        article.update!(internal: false)
      end

      describe 'created_article' do
        let(:template) { "\#{created_article.body}" }

        it 'has body content from the new article' do
          expect(renderer.render).to eq "&gt; #{ticket.articles.last.body}<br>"
        end
      end

      describe 'created_internal_article' do
        let(:template) { "\#{created_internal_article.body}" }

        it 'no such object' do
          expect(renderer.render).to eq '#{created_internal_article / no such object}' # rubocop:disable Lint/InterpolationCheck
        end
      end

      describe 'created_external_article' do
        let(:template) { "\#{created_external_article.body}" }

        it 'has body content from the new article' do
          expect(renderer.render).to eq "&gt; #{ticket.articles.last.body}<br>"
        end
      end

      describe 'last_article' do
        let(:template) { "\#{last_article.body}" }

        it 'has body content from the last article' do
          expect(renderer.render).to eq "&gt; #{ticket.articles.last.body}<br>"
        end
      end
    end
  end

  context 'when updating ticket attribute' do
    before do
      ticket.update!(title: 'New title')
    end

    describe 'last_article' do
      let(:template) { "\#{last_article.body}" }

      it 'has body content from the last article' do
        expect(renderer.render).to eq "&gt; #{ticket.articles.last.body}<br>"
      end
    end

    describe 'created_article' do
      let(:template) { "\#{created_article.body}" }

      it 'no such object' do
        expect(renderer.render).to eq '#{created_article / no such object}' # rubocop:disable Lint/InterpolationCheck
      end
    end
  end
end
