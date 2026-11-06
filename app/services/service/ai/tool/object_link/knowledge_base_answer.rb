# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# An answer opens in the locale of the text a row names, in its knowledge base.
class Service::AI::Tool::ObjectLink::KnowledgeBaseAnswer < Service::AI::Tool::ObjectLink
  page 'KnowledgeBase::Answer'

  def self.pages(rows)
    knowledge_bases = ::KnowledgeBase::Answer.joins(:category).where(id: rows.pluck('id')).pluck(:id, 'knowledge_base_categories.knowledge_base_id').to_h

    rows.each_with_object({}.compare_by_identity) do |row, pages|
      knowledge_base_id = knowledge_bases[row['id']]
      next if knowledge_base_id.nil? || row['locale'].blank?

      pages[row] = "knowledge_base/#{knowledge_base_id}/locale/#{row['locale']}/answer/#{row['id']}"
    end
  end

  def self.label_of(row, **)
    "Knowledge base answer #{row['id']} · #{row['locale']}"
  end
end
