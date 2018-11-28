require 'json'
require 'net/http'
require 'net/https'
require 'uri'
require 'rest-client'

class SigarilloAPI
  def initialize(api_url, token)
    @token = token
    @last_update = 0
    @api = api_url
  end

  def parse_hash(hash)
    ret = {}
    hash.map do |k, v|
      ret[k] = CGI.encode(v.to_s.gsub('\\\'', '\''))
    end
    ret
  end

  def get(api)
    url = @api + '/bot/' + @token + '/' + api
    ret = JSON.parse(RestClient.get(url, { accept: :json }).body)
    ret
  end

  def post(api, params = {})
    url = @api + '/bot/' + @token + '/' + api
    ret = JSON.parse(RestClient.post(url, params, { accept: :json }).body)
    ret
  end

  def fetch_self
    get('')
  end

  def send_message(recipient, text, options = {})
    post('send', { recipient: recipient.to_s, message: text }.merge(parse_hash(options)))
  end

  def fetch
    results = get('receive')
    if results['messages'].nil?
      Rails.logger.error { 'sigarillo fetch failed' }
      Rails.logger.debug { results.inspect }
      return []
    end

    messages = results['messages']
    messages
  end
end
