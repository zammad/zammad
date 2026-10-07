# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module ChecklistActions
  # The ticket zoom may render its sidebar again once the checklist has loaded, which resets it
  #   to the first tab and drops an earlier click. Clicking the active tab would collapse it.
  #   Checks for the checklist itself, the factory's checklist name is blank and found anywhere.
  def open_checklist_sidebar
    wait(30).until do
      click '.tabsSidebar-tab[data-tab=checklist]' if page.has_no_css?('.tabsSidebar-tab.active[data-tab=checklist]', wait: 0)

      page.has_css?('.sidebar[data-tab=checklist] .checklistShow', wait: 1)
    end
  end
end

RSpec.configure do |config|
  config.include ChecklistActions, type: :system
end
