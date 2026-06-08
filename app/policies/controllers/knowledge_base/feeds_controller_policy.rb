# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Controllers::KnowledgeBase::FeedsControllerPolicy < Controllers::ApplicationControllerPolicy
  USER_REQUIRED = false

  def index?
    access?
  end

  def root?
    access?
  end

  def category?
    access?
  end

  private

  def access?
    user&.permissions?('knowledge_base.*') ||
      Token.check(action: 'KnowledgeBaseFeed', token: given_token)&.permissions?('knowledge_base.*')
  end

  def given_token
    record.params[:token]
  end
end
