# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# An overview opens by its link, in both interfaces.
class Service::AI::Tool::ObjectLink::Overview < Service::AI::Tool::ObjectLink
  page 'Overview'

  def self.pages(rows)
    links = ::Overview.where(id: rows.pluck('id')).pluck(:id, :link).to_h

    rows.each_with_object({}.compare_by_identity) do |row, pages|
      pages[row] = "ticket/view/#{links[row['id']]}" if links[row['id']]
    end
  end
end
