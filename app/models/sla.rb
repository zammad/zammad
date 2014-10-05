# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

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
    Ticket::Escalation.rebuild_all
  end
end
