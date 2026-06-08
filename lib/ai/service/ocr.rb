# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class AI::Service::OCR < AI::Service
  def self.lookup_attributes(context_data, _locale)
    {
      identifier:        'ocr',
      related_object_id: context_data[:store].store_file_id,
    }
  end

  def self.lookup_version(context_data, _locale)
    context_data[:store].store_file.sha
  end

  def analytics?
    true
  end

  def persistable?
    true
  end

  private

  def options
    {
      temperature: 0.1,
    }
  end

  def json_response?
    false
  end
end
