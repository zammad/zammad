# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Overview < ApplicationModel
  store     :condition
  store     :order
  store     :view
  validates :name, presence: true
  validates :prio, presence: true

  before_create :fill_link
  before_update :fill_link

  notify_clients_support
  latest_change_support

  private

  # fill link
  def fill_link
    return true if link.empty?
    return true if !changes['name']
    self.link = name.downcase
    link.gsub!(/\s/, '_')
    link.gsub!(/[^0-9a-z]/i, '_')
    link.gsub!(/_+/, '_')
  end

end
