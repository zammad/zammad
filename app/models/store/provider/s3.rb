# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
class Store::Provider::S3
  """
  AWS_ACCESS_KEY_ID
  AWS_SECRET_ACCESS_KEY
  AWS_DEFAULT_REGION
  AWS_PROFILE
  ZAMMAD_ATTACHMENTS_BUCKET
  ZAMMAD_ATTACHMENTS_PREFIX
  """
  s3 = Aws::S3::Resource.new
  bucket =  s3.bucket(ENV.get('ZAMMAD_ATTACHMENTS_BUCKET', 'media'))

  # get presigned url for upload to s3
  def self.get_presigned_url(filename)
    # install file
    location = get_location(sha)
    key_exists = @bucket.object(location).exist?(location)

    obj = s3.bucket('BucketName').object('KeyName')

    URI.parse(obj.presigned_url(:put))

  end


  # unlink file from s3
  def self.delete(sha)
  end

  # generate file location
  def self.get_location(sha)

  end

end
