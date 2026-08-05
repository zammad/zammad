# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# A relevance score threshold in percent. Values arrive as strings from the admin form input, so the
# numeric shape is checked here instead of relying on the stored type.
class Setting::Validation::AIRelevanceScore < Setting::Validation::Base

  def run
    return result_success if value.to_s.match?(%r{\A\d+\z}) && value.to_i.between?(0, 100)

    result_failed(__('The relevance score must be a number between 0 and 100.'))
  end

end
