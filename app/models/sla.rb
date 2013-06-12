# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

require 'cache'

class Sla < ApplicationModel
  store     :condition
  store     :data
  validates :name, :presence => true

  after_create  :escalation_calculation_rebuild
  after_update  :escalation_calculation_rebuild
  after_destroy :escalation_calculation_rebuild

  private
  def escalation_calculation_rebuild
    Cache.delete( 'SLA::List::Active' )
    Ticket.escalation_calculation_rebuild
  end
end
