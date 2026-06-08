# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::User::Overview::UpdateOrder < Service::Base
  requires_current_user!

  attr_reader :overviews

  def initialize(overviews)
    @overviews = overviews
  end

  def execute
    ActiveRecord::Base.transaction do
      reset_existing
      create_new
    end
  end

  private

  def reset_existing
    ::User::OverviewSorting
      .where(user: current_user)
      .destroy_all
  end

  def create_new
    overviews.each do |overview|
      overview
        .overview_sortings
        .create! user: current_user
    end
  end
end
