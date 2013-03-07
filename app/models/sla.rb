class Sla < ApplicationModel
  store     :condition
  store     :data
  validates :name, :presence => true

  after_create :escalation_calculation_rebuild
  after_update :escalation_calculation_rebuild

  private
    def escalation_calculation_rebuild
      Ticket.escalation_calculation_rebuild
    end
end