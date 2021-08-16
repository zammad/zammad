# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class KnowledgeBase::Public::TagsController < KnowledgeBase::Public::BaseController
  def show
    @object = [:tag, params[:tag]]

    all_tagged = KnowledgeBase::Answer.tag_objects(params[:tag])

    @answers = policy_scope(all_tagged)
               .localed(system_locale_via_uri)
               .sorted
  end
end
