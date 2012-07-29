class Translation < ActiveRecord::Base
  before_create :set_initial

  private
    def set_initial
      self.target_initial = self.target
    end
end
