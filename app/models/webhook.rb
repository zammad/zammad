class Webhook < ApplicationModel
  self.table_name = 'webhooks'

  validates :url, presence: true, format: { with: %r{\A(http|https)://[a-z0-9]+([\-.]{1}[a-z0-9]+)*\.[a-z]{2,63}(:[0-9]{1,5})?(/.*)?\z}ix }
end
