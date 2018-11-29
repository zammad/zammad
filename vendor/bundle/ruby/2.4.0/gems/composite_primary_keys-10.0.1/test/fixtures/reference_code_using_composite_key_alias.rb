class ReferenceCodeUsingCompositeKeyAlias < ActiveRecord::Base
  self.table_name = 'reference_codes'
  self.primary_key = [:reference_type_id, :reference_code]
  
  belongs_to :reference_type, :foreign_key => "reference_type_id"
  
  validates_presence_of :reference_code, :code_label, :abbreviation
end
