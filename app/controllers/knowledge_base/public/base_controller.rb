# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class KnowledgeBase::Public::BaseController < ApplicationController
  before_action :load_kb
  helper_method :system_locale_via_uri, :fallback_locale, :current_user, :find_category,
                :filter_primary_kb_locale, :menu_items, :all_locales, :can_preview?

  layout 'knowledge_base'

  include KnowledgeBaseHelper

  private

  def load_kb
    @knowledge_base = policy_scope(KnowledgeBase)
                      .localed(guess_locale_via_uri)
                      .first

    raise ActiveRecord::RecordNotFound if @knowledge_base.nil?
  end

  def all_locales
    @all_locales ||= KnowledgeBase::Locale.system_with_kb_locales(@knowledge_base)
  end

  def menu_items
    @menu_items ||= KnowledgeBase::MenuItem.using_locale(guess_locale_via_uri || filter_primary_kb_locale)
  end

  def system_locale_via_uri
    @system_locale_via_uri ||= guess_locale_via_uri || filter_primary_kb_locale || all_locales.first
  end

  def fallback_locale
    return system_locale_via_uri if all_locales.find { |locale| locale.id == system_locale_via_uri&.id }

    filter_primary_kb_locale || all_locales.first
  end

  def filter_primary_kb_locale
    all_locales.find(&:primary_locale?)
  end

  def guess_locale_via_uri
    @guess_locale_via_uri ||= params[:locale].present? ? ::Locale.find_by(locale: params[:locale]) : nil
  end

  def find_category(id)
    @knowledge_base.load_category(system_locale_via_uri, id)
  end

  def find_locales(object)
    return [] if object.blank?

    system_locale_ids = KnowledgeBase::Locale.available_for(object).select(:system_locale_id).pluck(:system_locale_id)
    all_locales.select { |locale| system_locale_ids.include? locale.id }
  end

  def categories_filter(list)
    list
      .localed(system_locale_via_uri)
      .sorted
      .select { |category| policy(category).show_public? }
  end

  def answers_filter(list)
    answers = list
                .localed(system_locale_via_uri)
                .sorted

    if current_user&.permissions?('knowledge_base.editor')
      answers.filter { |answer| policy(answer).show_public? }
    else
      answers.published
    end
  end

  def find_answer(scope, id, locale: system_locale_via_uri)
    return if scope.nil?

    scope = scope.include_contents
    scope = scope.localed(locale) if locale

    if !current_user&.permissions?('knowledge_base.editor')
      return scope.published.find_by(id: id)
    end

    if (item = scope.find_by(id: id)) && policy(item).show_public?
      return item
    end

    nil
  end

  def can_preview?
    @can_preview ||= policy(@knowledge_base).update?
  end

  def not_found(e)
    @knowledge_base = policy_scope(KnowledgeBase).first

    if @knowledge_base.nil?
      super
      return
    end

    @page_title_error = :not_found
    render 'knowledge_base/public/not_found', status: :not_found
  end
end
