# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::KnowledgeBase::Answer::Update::Validator::Base

  attr_reader :user, :answer, :answer_data, :kb_locale

  def initialize(user: nil, answer: nil, answer_data: nil, kb_locale: nil)
    @user        = user
    @answer      = answer
    @answer_data = answer_data
    @kb_locale   = kb_locale
  end

  def valid!
    raise NotImplementedError
  end
end
