# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module ApplicationController::HasResponseExtentions
  extend ActiveSupport::Concern

  private

  def response_expand?
    ActiveModel::Type::Boolean.new.cast params[:expand]
  end

  def response_full?
    ActiveModel::Type::Boolean.new.cast params[:full]
  end

  def response_all?
    ActiveModel::Type::Boolean.new.cast params[:all]
  end

  def response_only_total_count?
    ActiveModel::Type::Boolean.new.cast params[:only_total_count]
  end
end
