class Observer::Ticket::Article::EmailSignatureDetection::BackgroundJob
  def initialize(id)
    @user_id = id
  end

  def perform
    SignatureDetection.rebuild_user(@user_id)
  end
end
