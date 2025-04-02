# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

class Service::User::Overview::UpdateOrder < Service::Base
  attr_reader :user, :overviews

  def initialize(user, overviews)
    super()

    @user = user
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
      .where(user:)
      .destroy_all
  end

  def create_new
    overviews.each do |overview|
      overview
        .overview_sortings
        .create! user:
    end
  end
end
