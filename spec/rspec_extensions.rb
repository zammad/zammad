# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# Small patch for rspec: don't treat --example-matches/-E as a standalone
#   filter that suppresses other exclusion filters, but combine all filters instead.
require 'rspec/core/filter_manager'
class RSpec::Core::InclusionRules
  def standalone?
    false
  end
end
