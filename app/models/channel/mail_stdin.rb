class Channel::MailStdin < Channel::EmailParser
  include UserInfo

  def initialize
    puts "read main from STDIN"

    msg = ARGF.read

    process( {}, msg )
  end
end