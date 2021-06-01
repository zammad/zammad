# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# Be sure to restart your server when you modify this file.

# Add new inflection rules using the following format. Inflections
# are locale specific, and you may define rules for as many different
# locales as you wish. All of these examples are active by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end

# These inflection rules are supported but not enabled by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.acronym 'RESTful'
# end

ActiveSupport::Inflector.inflections(:en) do |inflect|

  # Rails thinks the singularized version of knowledge_bases is knowledge_basis?!
  # see: KnowledgeBase.table_name.singularize
  inflect.singular(%r{(knowledge_base)s$}i, '\1')
  inflect.acronym 'SMIME'
  inflect.acronym 'GitLab'
  inflect.acronym 'GitHub'
end
