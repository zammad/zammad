# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Service::AI::Analytics::UpsertUsage < Service::Base
  attr_reader :user, :ai_analytics_run, :rating, :comment, :context

  def initialize(user, ai_analytics_run, rating: nil, comment: nil, context: nil)
    super()

    @user = user
    @ai_analytics_run = ai_analytics_run
    @rating = rating
    @comment = comment
    @context = context.deep_stringify_keys if !context.nil?
  end

  def execute
    usage.rating  = rating if !rating.nil?
    usage.comment = comment if !comment.nil?
    usage.context = usage.context.merge(context).compact if !context.nil?
    usage.save!

    usage
  end

  private

  def usage
    @usage ||= AI::Analytics::Usage
      .find_or_initialize_by(ai_analytics_run:, user:)
  end
end
