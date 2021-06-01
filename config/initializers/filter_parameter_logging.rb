# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

# Be sure to restart your server when you modify this file.

# Configure sensitive parameters which will be filtered from the log file.
Rails.application.config.filter_parameters += %i[password bind_pw state.body state.article.body article.body article.attachments.data attachments.data body]
