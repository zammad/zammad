class ExternalCredential < ActiveRecord::Base
  validates :name, presence: true
  store     :credentials
end
