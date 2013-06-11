#!/usr/bin/ruby
# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

require 'tempfile'
require 'code_beauty_ruby.rb'
def checkForHeader(fileName)
   foundHeader = false;
   foundSheBang = false;
   header = "# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/\n\n"

   file = File.open(fileName)
   t_file = Tempfile.new('Temp')
   allLines = IO.readlines(fileName)

   if allLines[0] =~ /(^# Copyright)/ || allLines[1] =~ /(^# Copyright)/
      foundHeader = true
   end
   if allLines[0] =~ /(^#!\/)/
      foundSheBang = true
   end

   file.each do |line|
      if file.lineno == 1 && foundSheBang && foundHeader
         t_file.puts line
      elsif file.lineno == 1 && !foundSheBang && !foundHeader
         t_file.puts header
         t_file.puts line
      elsif file.lineno == 1 && foundSheBang && !foundHeader
         t_file.puts line
         t_file.puts header
      else
         t_file.puts line.rstrip
      end
   end

   t_file.rewind
   t_file.close
   FileUtils.cp(t_file.path, fileName)
   t_file.unlink

   t_file = RBeautify.beautify_file(fileName)
end

#folder array
#folder = ['app/controllers/','app/models/', 'app/helpers/', 'app/mailers/']
#folder = ['app/controllers/', 'script']
folder = ['script/']

folder.each do |folder|
   puts 'Working on folder' + folder.to_s
   rbfiles = File.join("../#{folder}**", "*.rb")
   d = Dir.glob(rbfiles)

   d.each  {|fileName|
      puts "Working on #{fileName}"

      #check if file header is present
      checkForHeader(fileName)
   }
end
