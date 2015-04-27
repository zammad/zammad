# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

#require 'rubygems'
#require 'twitter'

class Channel::Facebook
  #  def fetch(:oauth_token, :oauth_token_secret)
  def fetch


  end

  def disconnect


  end

  def send

    logger.debug('face!!!!!!!!!!!!!!')
    graph_api = Koala::Facebook::API.new(
      'AAACqTciZAPsQBAHO9DbM333y2DcL5kccHyIObZB7WhaZBVUXUIeBNChkshvShCgiN6uwZC3r3l4cDvAZAPTArNIkemEraojzN1veNPZBADQAZDZD'
    )
    graph_api.put_object(
      'id',
      'comments',
      {
        message: self.body
      }
    )
    #            client.direct_message_create(
    #              'medenhofer',
    #              self.body,
    #              options = {}
    #            )
  end
end
