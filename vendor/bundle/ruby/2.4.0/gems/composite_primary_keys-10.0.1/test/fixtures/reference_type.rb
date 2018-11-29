class ReferenceType < ActiveRecord::Base
  self.primary_key = :reference_type_id
  has_many :reference_codes, :foreign_key => "reference_type_id", :dependent => :destroy
  accepts_nested_attributes_for :reference_codes

  validates_presence_of :type_label, :abbreviation
  validates_uniqueness_of :type_label

  before_destroy do |record|
    record
  end
end
