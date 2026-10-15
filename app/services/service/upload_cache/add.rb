# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Service::UploadCache::Add < Service::Base
  requires_current_user!

  attr_reader :form_id, :files

  def initialize(form_id:, files:)
    @form_id = form_id
    @files   = files
  end

  def execute
    files.each { |file| Pundit.authorize current_user, file[:attachment], :show? if file[:attachment] }

    cache = ::UploadCache.new(form_id)

    ActiveRecord::Base.transaction do
      files.map { |file| add_file(cache, file) }
    end
  end

  private

  def add_file(cache, file)
    attachment = file[:attachment]

    cache.add(
      data:          attachment ? attachment.content : file[:content],
      filename:      file[:name].presence || attachment&.filename,
      preferences:   preferences(file, attachment),
      created_by_id: current_user.id,
    )
  end

  # A copy never takes over the Content-ID of the attachment, the new article assigns its own.
  def preferences(file, attachment)
    preferences = { 'Content-Type' => file[:type].presence || attachment&.preferences&.values_at('Content-Type', 'Mime-Type')&.compact&.first }
    preferences['Content-Disposition'] = 'inline' if file[:inline]
    preferences
  end
end
