# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class Controllers::KnowledgeBase::FeedsControllerPolicy < Controllers::ApplicationControllerPolicy
  def root?
    access?
  end

  def category?
    access?
  end

  def user_required?
    false
  end

  private

  def access?
    user&.permissions?('knowledge_base.*') ||
      Token.check(action: 'KnowledgeBaseFeed', name: given_token)&.permissions?('knowledge_base.*')
  end

  def given_token
    record.params[:token]
  end
end
