# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

feed_options = { root_url: @root_url }

# On the public knowledge base @feed_url holds the feed's own URL, built from
# the (URL-safe) request path and rewritten for a custom address when one is
# configured. atom_feed otherwise derives the self link and Atom id from the
# raw request, which is served from the internal /help mount point (via the
# nginx rewrite) — so we pass them explicitly to keep that prefix out of the
# public feed. The internal feeds controller does not set @feed_url and keeps
# atom_feed's defaults. The 2005 tag date mirrors atom_feed's own default, so
# ids stay stable for existing installations.
if @feed_url
  feed_uri = URI(@feed_url)

  feed_options[:url] = @feed_url
  feed_options[:id]  = "tag:#{feed_uri.host},2005:#{feed_uri.path}"
end

atom_feed(feed_options) do |feed|
  author_name = @knowledge_base.translations.first.title

  feed.title kb_public_page_title(@knowledge_base, @category, nil)
  feed.updated updating_date(@answers.first) if @answers.any?

  @answers.each do |answer|
    translation  = answer.translations.first
    body         = simplify_rich_text(translation.content.body)

    hash = {
      url:       build_original_url(answer),
      id:        "kb-answer-#{translation.id}-#{translation.updated_at.to_i}",
      published: publishing_date(answer),
      updated:   updating_date(answer)
    }

    feed.entry(translation, hash) do |entry|
      entry.title   translation.title
      entry.author  do |author|
        author.name author_name
      end
      entry.content body, type: 'html'
    end
  end
end
