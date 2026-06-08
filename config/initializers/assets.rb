# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Configure Dart Sass (dartsass-rails) entry points.
# Maps source .scss files to their compiled .css output in app/assets/builds/.
# Add dartsass output directory to Sprockets load path so compiled CSS is found.
Rails.application.config.assets.paths << Rails.root.join('app/assets/builds')

# Setup DartSASS only if the gem is loaded.
# Otherwise config.dartsass does not exist
if defined?(Dartsass)
  Rails.application.config.dartsass.builds = {
    'zammad.scss'         => 'zammad.css',
    'print.scss'          => 'print.css',
    'knowledge_base.scss' => 'knowledge_base.css',
  }
end
