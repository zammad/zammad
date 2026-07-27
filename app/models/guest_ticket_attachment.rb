class GuestTicketAttachment < ApplicationRecord
  belongs_to :guest_ticket

  has_one_attached :file

  validates :file, presence: true
  validates :original_filename, presence: true

  MAX_FILE_SIZE = 10.megabytes

  validate :file_size_validation
  validate :file_type_validation

  scope :recent, -> { order(created_at: :desc) }

  ALLOWED_CONTENT_TYPES = [
    'image/png',
    'image/jpeg',
    'image/jpg',
    'image/gif',
    'image/webp',
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  ].freeze

  private

  def file_size_validation
    if file.blob && file.blob.byte_size > MAX_FILE_SIZE
      errors.add(:file, "must be less than #{MAX_FILE_SIZE / 1.megabyte}MB")
    end
  end

  def file_type_validation
    if file.blob && !ALLOWED_CONTENT_TYPES.include?(file.blob.content_type)
      errors.add(:file, 'type is not allowed')
    end
  end
end
