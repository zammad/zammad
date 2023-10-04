# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

require 'aws-sdk-s3'

module Store::Provider::S3

  class Store::Provider::S3::Error < StandardError; end

  class << self

    def add(data, sha)
      if data.bytesize > Store::Provider::S3::Config.max_chunk_size
        return upload(data, sha, content_type:, filename:)
      end

      client.put_object(
        bucket: bucket,
        key:    sha,
        body:   data
      )

      true
    end

    def client
      @client.presence ||
        (Store::Provider::S3::Config.apply && @client = Aws::S3::Client.new)
    end

    def delete(sha)
      client.delete_object(
        bucket: bucket,
        key:    sha
      )

      true
    end

    def get(sha)
      object = client.get_object(
        bucket: bucket,
        key:    sha
      )
      object.body.read
    end

    def upload(data, sha)
      id    = Store::Provider::S3::Upload.create(sha)
      parts = Store::Provider::S3::Upload.process(data, sha, id)

      Store::Provider::S3::Upload.complete(sha, parts, id)

      true
    end

    def url(sha, expires_in: 3600)
      object = Aws::S3::Object.new(bucket_name: bucket, key: sha, client: client)
      object.presigned_url(:get, expires_in: expires_in)
    end

    def ping?
      return false if !client

      begin
        client.head_bucket(bucket: bucket)
        true
      rescue => e
        Rails.logger.error { "#{name}: #{e.message}" }
        false
      end
    end

    def ping!
      raise Store::Provider::S3::Error, __('Simple Storage Service not reachable.') if !ping?
    end

    def reset
      @client = nil
      Store::Provider::S3::Config.reset

      true
    end

    private

    def bucket
      Store::Provider::S3::Config.bucket
    end

  end
end
