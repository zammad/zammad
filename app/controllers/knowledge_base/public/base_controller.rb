# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class KnowledgeBase::Public::BaseController < ApplicationController
  before_action :load_kb
  helper_method :system_locale_via_uri, :fallback_locale, :current_user, :editor?, :find_category, :filter_primary_kb_locale, :menu_items, :all_locales

  layout 'knowledge_base'

  include KnowledgeBaseHelper

  private

  def load_kb
    @knowledge_base = KnowledgeBase
                      .check_active_unless_editor(current_user)
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
    if all_locales.find { |locale| locale.id == system_locale_via_uri&.id }
      system_locale_via_uri
    else
      filter_primary_kb_locale || all_locales.first
    end

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
      .to_a
      .select { |elem| elem.visible_content_for?(current_user) }
  end

  def find_answer(scope, id)
    return if scope.nil?

    scope
      .localed(system_locale_via_uri)
      .include_contents
      .check_published_unless_editor(current_user)
      .find_by(id: id)
  end

  def editor?
    current_user&.permissions? 'knowledge_base.editor'
  end

  def not_found(e)
    @knowledge_base = KnowledgeBase.check_active_unless_editor(current_user).first

    if @knowledge_base.nil?
      super
      return
    end

    @page_title_error = :not_found
    render 'knowledge_base/public/not_found'
  end
end
