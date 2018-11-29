class PkCalledId < ActiveRecord::Base
  self.primary_keys = :id, :reference_code

  validates_presence_of :reference_code, :code_label, :abbreviation
end
