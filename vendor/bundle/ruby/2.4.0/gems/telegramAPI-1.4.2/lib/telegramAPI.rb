require 'json'
require 'net/http'
require 'net/https'
require 'uri'
require 'rest-client'

# This library provides an easy way to access to the Telegram Bot API
# Author:: Benedetto Nespoli
# License:: MIT

class TelegramAPI
  @@core = "https://api.telegram.org/bot"

  def initialize token
    @token = token
    @last_update = 0
  end

  def parse_hash hash
    ret = {}
    hash.map do |k,v|
      ret[k]=URI::encode(v.to_s.gsub("\\\"", "\""))
    end
    return ret
  end

  def query api, params={}
    r = JSON.parse(RestClient.post(@@core+@token+"/"+api, params).body)
    if r['result'].class==Array and r['result'][-1]!=nil then @last_update=r['result'][-1]['update_id']+1 end
    return r["result"]
  end

  def post api, name, path, to, options={}
    JSON.parse(RestClient.post(@@core+@token+api, {name=>File.new(path,'rb'), :chat_id=>to.to_s}.merge(parse_hash(options))).body)["result"]
  end
  
  def setWebhook url
    self.query("setWebhook", {"url"=>URI::encode(url)})
  end

  def getUpdates options={"timeout"=>0, "limit"=>100}
    self.query("getUpdates", {"offset"=>@last_update.to_s}.merge(parse_hash(options)))
  end

  def getMe
    self.query("getMe")
  end

  def sendMessage to, text, options={}
    if options.has_key?"reply_markup" then
      options["reply_markup"]=options["reply_markup"].to_json
    end
    self.query("sendMessage", {:chat_id=>to.to_s, :text=>text}.merge(parse_hash(options)))
  end

  def forwardMessage to, from, msg
    self.query("forwardMessage", {:chat_id=>to, :from_chat_id=>from, :message_id=>msg})
  end

  def sendPhoto to, path, options={}
    self.post("/sendPhoto", :photo, path, to, options)
  end

  def sendAudio to, path, options={}
    self.post("/sendAudio", :audio, path, to, options)
  end

  def sendDocument to, path, options={}
    self.post("/sendDocument", :document, path, to, options)
  end

  def sendStickerFromFile to, path, options={}
    self.post("/sendSticker", :sticker, path, to, options)
  end

  def sendSticker to, id, options={}
    RestClient.post(@@core+@token+"/sendSticker", {:sticker=>id, :chat_id=>to.to_s}.merge(parse_hash(options))).body
  end

  def sendVideo to, path, options={}
    self.post("/sendVideo", :video, path, to, options)
  end

  def sendVoice to, path, options={}
    self.post("/sendVoice", :voice, path, to, options)
  end

  def sendLocation to, lat, long, options={}
    self.query("sendLocation", {:chat_id=>to, :latitude=>lat, :longitude=>long}.merge(parse_hash(options)))
  end
  
  def sendVenue to, lat, long, title, address, options={}
    self.query("sendVenue", {:chat_id=>to, :latitude=>lat, :longitude=>long, :title=>title, :address=>address}.merge(parse_hash(options)))
  end
  
  def sendContact to, phone_number, first_name, options={}
    self.query("sendContact", {:chat_id=>to, :phone_number=>phone_number, :first_name=>first_name}.merge(parse_hash(options)))
  end

  # act is one between: typing, upload_photo, record_video, record_audio, upload_audio, upload_document, find_location
  def sendChatAction to, act
    self.query("sendChatAction", {:chat_id=>to, :action=>act})
  end

  def getUserProfilePhotos id, options={}
    self.query("getUserProfilePhotos", {:user_id=>id}.merge(parse_hash(options)))
  end
  
  def getFile file_id
    self.query("getFile", {:file_id=>file_id})
  end
  
  def kickChatMember chat_id, user_id
    self.query("kickChatMember", {:chat_id=>chat_id, :user_id=>user_id})
  end
  
  def leaveChat chat_id
    self.query("leaveChat", {:chat_id=>chat_id})
  end
  
  def unbanChatMember chat_id, user_id
    self.query("unbanChatMember", {:chat_id=>chat_id, :user_id=>user_id})
  end
  
  def getChat chat_id
    self.query("getChat", {:chat_id=>chat_id})
  end
  
  def getChatAdministrators chat_id
    self.query("getChatAdministrators", {:chat_id=>chat_id})
  end
  
  def getChatMembersCount chat_id
    self.query("getChatMembersCount", {:chat_id=>chat_id})
  end
  
  def getChatMember chat_id, user_id
    self.query("getChatMember", {:chat_id=>chat_id, :user_id=>user_id})
  end
  
  def answerInlineQuery inline_query_id, results
    self.query("answerInlineQuery", {:inline_query_id=>inline_query_id, :results=>JSON.dump(results)})
  end

  protected :query, :parse_hash, :post
end
