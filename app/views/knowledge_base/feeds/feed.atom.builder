# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

atom_feed(root_url: @root_url) do |feed|
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
