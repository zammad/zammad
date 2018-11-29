# TelegramAPI

[![Gem Version](https://badge.fury.io/rb/telegramAPI.svg)](https://badge.fury.io/rb/telegramAPI)
[![Dependency Status](https://gemnasium.com/bennesp/telegramAPI.svg)](https://gemnasium.com/bennesp/telegramAPI)
[![Code Climate](https://codeclimate.com/github/bennesp/telegramAPI/badges/gpa.svg)](https://codeclimate.com/github/bennesp/telegramAPI)

This is a simple and lightweight Ruby API for Telegram Bots.

With this tiny library you can create awesome Telegram Bot!

## Installation

```
sudo gem install telegramAPI
```

## Use

Import the library in your script with:

```ruby
require 'telegramAPI'
```

Obtain a token, if you haven't yet, talking with [@BotFather](https://telegram.me/botfather)

## Getting Started

To test your access token, you can use the *getMe* method
```ruby
require 'telegramAPI'

token = "******"
api = TelegramAPI.new(token)
bot = api.getMe()
puts "I'm bot #{bot['first_name']} with id #{bot['id']}"
puts "But you can call me @#{bot['username']}"
```

## Getting Updates

There are two ways of getting updates from Telegram.
The first one is the simpliest, but less powerful: **getUpdates**

### 1. getUpdates

```ruby
require 'telegramAPI'

token = "******"
api = TelegramAPI.new(token)
while true do
  updates = api.getUpdates({"timeout"=>180})
  updates.each do |update|
    usr = update['message']['chat']['username'] || "unknown"
    puts "Received update from @#{usr}"
  end
end
```

### 2. setWebhook

Using setWebhook is not so complicated, but you need a web server with https support enabled (for example: Openshift or Heroku)

In the example below I will use Sinatra framework for the Web Server.

```ruby
require 'telegramAPI'
require 'sinatra'
require 'json'

token = "******"
api = TelegramAPI.new token

post "/#{token}" do
  status 200
  # Get Telegram Data
  request.body.rewind
  data = JSON.parse(request.body.read)
  
  # Output data on stdout
  p data
  # Return an empty json, to say "ok" to Telegram
  "{}"
end

r = api.setWebhook("https://YOUR_URL/#{token}").to_json
puts "setWebhook Result: #{r}" 
```


## Documentation

You can use the Telegram official [documentation](https://core.telegram.org/bots/api#available-methods)

## List of available methods

Every method has a optional parameter. See the Send Custom Keyboard example for more.

 * ```getUpdates()```
 * ```setWebhook(url)```
 * ```getMe()```
 * ```sendMessage(chat_id, text)```
 * ```forwardMessage(chat_id, from_chat_id, message_id)```
 * ```sendPhoto(chat_id, path)```
 * ```sendAudio(chat_id, path)```
 * ```sendDocument(chat_id, path)```
 * ```sendStickerFromFile(chat_id, path)```
 * ```sendSticker(chat_id, sticker_id)```
 * ```sendVideo(chat_id, path)```
 * ```sendVoice(chat_id, path)```
 * ```sendLocation(chat_id, latitude, longitude)```
 * ```sendVenue(chat_id, latitude, longitude, title, address)```
 * ```sendContact(chat_id, phone_number, first_name)```
 * ```sendChatAction(chat_id, action)```
 * ```getUserProfilePhotos(user_id)```
 * ```getFile(file_id)```
 * ```kickChatMember(chat_id, user_id)```
 * ```leaveChat(chat_id)```
 * ```unbanChatMember(chat_id, user_id)```
 * ```getChat(chat_id)```
 * ```getChatAdministrators(chat_id)```
 * ```getChatMembersCount(chat_id)```
 * ```getChatMember(chat_id, user_id)```

## Examples

### Echo Server

```ruby
token = "******"
api = TelegramAPI.new token
while true do
  # Get last messages if there are, or wait 180 seconds for new messages
  u=api.getUpdates({"timeout"=>180})
  u.each do |m|
    api.sendMessage(m['message']['chat']['id'], m['message']['text'])
  end
end
```

### Send Media

```ruby
api.sendSticker m['message']['chat']['id'], sticker_id

api.sendPhoto m['message']['chat']['id'], "/home/path-of-image/image.jpg"

api.sendDocument m['message']['chat']['id'], "/home/path-of-document/doc.gif"

api.sendAudio m['message']['chat']['id'], "/home/path-of-audio/audio.opus"

api.sendVideo m['message']['chat']['id'], "/home/path-of-video/video.mp4"

api.sendLocation m['message']['chat']['id'], 45.462781, 9.177732
```
**Note:** According to Telegram, each audio must be encoded in **Ogg OPUS**, and each video must be encoded in **mp4**.

### Send Custom Keyboards

You can find the complete list of options at the offical [Telegram API Bots](https://core.telegram.org/bots/api#replykeyboardhide) page.

```ruby
markup = {
  "keyboard"=>[["YES!", "Yes"], ["Well..", "No.."]],
  # Other optional settings:
  "resize_keyboard"=>true,
  "one_time_keyboard"=>true,
  "selective"=>true,
  "force_reply"=>true
  # "hide_keyboard"=>true
}

api.sendMessage m['message']['chat']['id'], "Am I sexy?", {"reply_markup"=>markup}
```

### Answer to inline query

```ruby
while true do
  updates = api.getUpdates({:timeout=>180})
  updates.each do |u|
    if(u['inline_query']!=nil) then
      r = api.answerInlineQuery(u['inline_query']['id'], [
        {
          :type=>'article',
          :id=>"1",
          :title=>"Test 1",
          :input_message_content=>{:message_text=>"test content 1"}
        },{
          :type=>'article',
          :id=>"2",
          :title=>"Test 2",
          :input_message_content=>{:message_text=>"test content 2"}
        },{
          :type=>'article',
          :id=>"3",
          :title=>"Test 3",
          :input_message_content=>{:message_text=>"test content 3"}
        }
      ])
    end
  end
end
```