# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

path = Rails.root.join('app/assets/stylesheets/custom_knowledge_base_public/*.css')
Rails.application.config.knowledge_base_custom_css_present = Dir.glob(path).any?
