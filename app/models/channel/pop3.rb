#http://blog.ethanvizitei.com/2008/06/using-ruby-for-imap-with-gmail.html


pop = Net::POP3.new("pop.gmail.com", port)
pop.enable_ssl
pop.start('YourAccount', 'YourPassword') 
if pop.mails.empty?
  puts 'No mail.'
else
  i = 0
  pop.each_mail do |m| 
    File.open("inbox/#{i}", 'w') do |f|
      f.write m.pop
    end
    m.delete
    i += 1
  end
  puts "#{pop.mails.size} mails popped."
end
pop.finish 
