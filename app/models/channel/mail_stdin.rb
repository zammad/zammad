class Channel::MailStdin < Channel::EmailParser
  def initialize
    puts "read main from STDIN"

    msg = ARGF.read

    process( {}, msg )
  end
end