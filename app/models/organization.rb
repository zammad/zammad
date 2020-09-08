# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/

class Organization < ApplicationModel
  include HasActivityStreamLog
  include ChecksClientNotification
  include ChecksLatestChangeObserved
  include HasHistory
  include HasSearchIndexBackend
  include CanCsvImport
  include ChecksHtmlSanitized
  include HasObjectManagerAttributesValidation
  include HasTaskbars

  include Organization::Assets
  include Organization::Search
  include Organization::SearchIndex

  has_many :members, class_name: 'User', dependent: :destroy
  has_many :tickets, class_name: 'Ticket', dependent: :destroy

  before_create :domain_cleanup
  before_update :domain_cleanup

  validates :name,   presence: true
  validates :domain, presence: { message: 'required when Domain Based Assignment is enabled' }, if: :domain_assignment

  activity_stream_permission 'admin.role'

  sanitized_html :note

  private

  def domain_cleanup
    return true if domain.blank?

    domain.gsub!(/@/, '')
    domain.gsub!(/\s*/, '')
    domain.strip!
    domain.downcase!
    true
  end

end
