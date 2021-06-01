# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

class KnowledgeBase::MenuItem < ApplicationModel
  belongs_to :kb_locale, class_name: 'KnowledgeBase::Locale', inverse_of: :menu_items, touch: true

  validates :title,    presence: true, length:    { maximum: 100 }
  validates :url,      presence: true, length:    { maximum: 500 }
  validates :location, presence: true, inclusion: { in: %w[header footer] }

  acts_as_list scope: %i[kb_locale_id location], top_of_list: 0

  scope :sorted,       ->           { order(position: :asc) }
  scope :using_locale, ->(locale)   { locale.present? ? joins(:kb_locale).where(knowledge_base_locales: { system_locale_id: locale.id } ) : none }
  scope :location,     ->(location) { sorted.where(location: location) }

  scope :location_header, -> { location(:header) }
  scope :location_footer, -> { location(:footer) }

  private

  def add_protocol_prefix
    return if url.blank?

    url.strip!

    return if url.match? %r{^\S+://}
    return if url[0] == '/'

    self.url = "http://#{url}"
  end

  before_validation :add_protocol_prefix
end
