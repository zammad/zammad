# Copyright (C) 2012-2025 Zammad Foundation, https://zammad-foundation.org/

module Store::Provider::S3::Upload
  class << self

    def complete(sha, parts, id)
      Store::Provider::S3.client.complete_multipart_upload(
        bucket:           bucket,
        key:              sha,
        multipart_upload: { parts: parts },
        upload_id:        id
      )
    end

    def create(sha)
      info = Store::Provider::S3.client.create_multipart_upload(
        bucket: bucket,
        key:    sha
      )

      info['upload_id']
    end

    def process(data, sha, id)
      divide(data).each_with_index.map do |chunk, index|
        number = index + 1

        part = Store::Provider::S3.client.upload_part(
          {
            body:        chunk,
            bucket:      bucket,
            key:         sha,
            part_number: number,
            upload_id:   id
          }
        )

        {
          etag:        part.etag,
          part_number: number
        }
      end
    end

    private

    def divide(data)
      size = Store::Provider::S3::Config.max_chunk_size

      Array.new(((data.length + size - 1) / size)) do |index|
        data.byteslice(index * size, size)
      end
    end

    def bucket
      Store::Provider::S3::Config.bucket
    end

  end
end
