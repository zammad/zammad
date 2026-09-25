# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::AI::Analytics::UpsertUsage < Service::Base
  requires_current_user!

  attr_reader :ai_analytics_run, :rating, :comment, :context

  def initialize(ai_analytics_run, rating: nil, comment: nil, context: nil)
    @ai_analytics_run = ai_analytics_run
    @rating = rating
    @comment = comment
    @context = context.deep_stringify_keys if !context.nil?
  end

  def execute
    AI::Analytics::Usage.transaction do
      # The same user may submit from several open views at once, so the check has to see the other writes.
      raise FeedbackAlreadyProvidedError if feedback_already_provided?

      usage.rating  = rating if !rating.nil?
      usage.comment = comment if !comment.nil?
      usage.context = usage.context.merge(context).compact if !context.nil?
      usage.save!

      usage
    end
  end

  private

  def usage
    @usage ||= AI::Analytics::Usage
      .lock
      .find_or_initialize_by(ai_analytics_run:, user: current_user)
  end

  def feedback_already_provided?
    return true if !rating.nil? && !usage.rating.nil?

    !comment.nil? && !usage.comment.nil?
  end

  class FeedbackAlreadyProvidedError < Exceptions::UnprocessableContent
    def initialize
      super(__('You have already provided feedback, thank you.'))
    end
  end
end
