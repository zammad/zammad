# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class KnowledgeBase::FeedTokensController < ApplicationController
  prepend_before_action :authentication_check

  def show
    token = Token.ensure_token! 'KnowledgeBaseFeed', persistent: true

    render json: { token: token }
  end

  def update
    new_token = Token.renew_token! 'KnowledgeBaseFeed', persistent: true

    render json: { token: new_token }
  end
end
