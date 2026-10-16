# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

module ImageHelper

=begin

  file_attributes = ImageHelper.data_url_attributes(data_url)

returns

  {
    mime_type: 'image/png',
    content: image_bin_content,
    file_extention: 'png',
  }

=end

  def self.data_url_attributes(data_url)
    data = {}
    if data_url =~ %r{^data:(.+?);base64,(.+?)$}
      data[:mime_type] = $1
      data[:content]   = Base64.decode64($2)
      if data[:mime_type] =~ %r{/(.+?)$}
        data[:file_extention] = $1
      end
      return data
    end
    raise "Unable to parse data url: #{data_url&.slice(0, 100)}"
  end

=begin

  mime_type = ImageHelper.mime_type(image_bin_content)

returns the type detected from the content, 'application/octet-stream' for unknown content

=end

  # Only the bytes decide: given a file name or a declared type, Marcel falls back
  # to those when the content matches nothing.
  def self.mime_type(content)
    Marcel::MimeType.for(StringIO.new(content))
  end
end
