class Chat::Session < ApplicationModel
  before_create :generate_session_id
  store         :preferences

  def generate_session_id
    self.session_id = Digest::MD5.hexdigest(Time.zone.now.to_s + rand(99_999_999_999_999).to_s)
  end

  def add_recipient(client_id, store = false)
    if !preferences[:participants]
      preferences[:participants] = []
    end
    return preferences[:participants] if preferences[:participants].include?(client_id)
    preferences[:participants].push client_id
    if store
      save
    end
    preferences[:participants]
  end

  def send_to_recipients(message, ignore_client_id = nil)
    preferences[:participants].each {|local_client_id|
      next if local_client_id == ignore_client_id
      Sessions.send(local_client_id, message)
    }
    true
  end

  def position
    return if state != 'waiting'
    position = 0
    Chat::Session.where(state: 'waiting').order('created_at ASC').each {|chat_session|
      position += 1
      break if chat_session.id == id
    }
    position
  end
end
