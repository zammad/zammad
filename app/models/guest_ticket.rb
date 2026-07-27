class GuestTicket < ApplicationRecord
  include AASM

  # Associations
  belongs_to :ticket, optional: true
  has_many :attachments, dependent: :destroy
  has_many :status_updates, dependent: :destroy

  # Validations
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :ticket_type, presence: true, inclusion: { in: %w(incident change_request service_request) }
  validates :title, presence: true, length: { minimum: 3, maximum: 100 }
  validates :description, presence: true, length: { minimum: 10, maximum: 2000 }
  validate :validate_specific_data

  # Enums
  enum status: { pending: 0, submitted: 1, assigned: 2, in_progress: 3, resolved: 4, closed: 5 }
  enum ticket_type: { incident: 0, change_request: 1, service_request: 2 }

  # AASM State Machine
  aasm column: 'aasm_state', timestamps: true do
    state :pending, initial: true
    state :submitted
    state :assigned
    state :in_progress
    state :resolved
    state :closed

    event :submit do
      transitions from: :pending, to: :submitted
    end

    event :assign do
      transitions from: :submitted, to: :assigned
    end

    event :start_work do
      transitions from: :assigned, to: :in_progress
    end

    event :resolve do
      transitions from: :in_progress, to: :resolved
    end

    event :close do
      transitions from: :resolved, to: :closed
    end
  end

  scope :recent, -> { order(created_at: :desc) }
  scope :unassigned, -> { where(ticket_id: nil) }
  scope :by_type, ->(type) { where(ticket_type: type) }
  scope :by_email, ->(email) { where(email: email) }

  before_create :generate_reference_number

  def incident_data
    specific_data['incident'] || {}
  end

  def change_request_data
    specific_data['change_request'] || {}
  end

  def service_request_data
    specific_data['service_request'] || {}
  end

  def priority_label
    case specific_data['priority']
    when 'critical'
      'Critical - Service doesn\'t work for everyone'
    when 'high'
      'High - Part of service doesn\'t work'
    when 'normal'
      'Normal - Issue for me only'
    end
  end

  def service_label
    case specific_data.dig('incident', 'service')
    when 'applications'
      'Applications'
    when 'hardware'
      'Hardware'
    when 'other'
      'Other'
    end
  end

  def change_size_label
    case specific_data.dig('change_request', 'changeSize')
    when 's'
      'Small (< 2 hours)'
    when 'm'
      'Medium (2-4 hours)'
    when 'l'
      'Large (4-8 hours)'
    when 'xl'
      'Very Large (8-16 hours)'
    when 'xxl'
      'Massive (> 16 hours)'
    end
  end

  def send_confirmation_email
    GuestTicketMailer.confirmation_email(self).deliver_later
  end

  def send_status_update_email
    GuestTicketMailer.status_update_email(self).deliver_later
  end

  private

  def generate_reference_number
    self.reference_number = "#{ticket_type[0].upcase}#{Date.today.strftime('%Y%m%d')}-#{SecureRandom.random_bytes(4).unpack1('H*').upcase[0..7]}"
  end

  def validate_specific_data
    return if specific_data.blank?

    case ticket_type
    when 'incident'
      validate_incident_data
    when 'change_request'
      validate_change_request_data
    when 'service_request'
      validate_service_request_data
    end
  end

  def validate_incident_data
    incident = specific_data['incident'] || {}
    errors.add(:specific_data, 'Service is required') if incident['service'].blank?
    errors.add(:specific_data, 'Priority is required') if incident['priority'].blank?
  end

  def validate_change_request_data
    change_req = specific_data['change_request'] || {}
    errors.add(:specific_data, 'Approver email is required') if change_req['approverEmail'].blank?
    errors.add(:specific_data, 'Urgency is required') if change_req['urgency'].blank?
    errors.add(:specific_data, 'Change size is required') if change_req['changeSize'].blank?
  end

  def validate_service_request_data
    service_req = specific_data['service_request'] || {}
    request_type = service_req['requestType']

    case request_type
    when 'password_reset'
      errors.add(:specific_data, 'System is required') if service_req['system'].blank?
      errors.add(:specific_data, 'Login is required') if service_req['login'].blank?
    when 'starter_form'
      errors.add(:specific_data, 'First name is required') if service_req['firstName'].blank?
      errors.add(:specific_data, 'Last name is required') if service_req['lastName'].blank?
      errors.add(:specific_data, 'Approver email is required') if service_req['approverEmail'].blank?
    when 'leaver_form'
      errors.add(:specific_data, 'Employee ID is required') if service_req['employeeId'].blank?
      errors.add(:specific_data, 'Departure type is required') if service_req['departureType'].blank?
    when 'transfer_form'
      errors.add(:specific_data, 'Employee ID is required') if service_req['employeeId'].blank?
    when 'information_request'
      errors.add(:specific_data, 'Information requested is required') if service_req['informationRequested'].blank?
    end
  end
end
