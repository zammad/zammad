#!/usr/bin/ruby
# Copyright (C) 2012-2013 Zammad Foundation, http://zammad-foundation.org/

require 'tempfile'
require 'code_beauty_ruby.rb'

def checkForHeader(fileName)
  foundHeader = false;
  foundSheBang = false;
  isCoffee = false;

  header = "# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/\n"
  if File.extname(fileName) == '.coffee'
    isCoffee = true
  end

  # read file
  file = File.open(fileName)
  t_file = Tempfile.new('Temp')
  allLines = IO.readlines(fileName)

  # detect file type
  if allLines[0] =~ /(^# Copyright)/ || allLines[1] =~ /(^# Copyright)/
    foundHeader = true
  elsif allLines[1] =~ /^=begin/ #assume external script
    foundHeader = true
  end
  if allLines[0] =~ /(^#!\/)/
    foundSheBang = true
  end

  file.each do |line|
    # replace old header in script
    if file.lineno == 1 && foundSheBang && foundHeader
      t_file.puts header

    # insert new header
    elsif file.lineno == 1 && !foundSheBang && foundHeader
      t_file.puts header

    # insert new header
    elsif file.lineno == 1 && !foundSheBang && !foundHeader
      t_file.puts header
      t_file.puts line + "\n"

    # insert new header into script
    elsif file.lineno == 1 && foundSheBang && !foundHeader
      t_file.puts line
      t_file.puts header + "\n"

    # strip lines
    else
      t_file.puts line.rstrip
    end
  end

  # rename file
  t_file.rewind
  t_file.close
  FileUtils.cp(t_file.path, fileName)
  t_file.unlink

  # beautify ruby file
  if !isCoffee
    t_file = RBeautify.beautify_file(fileName)
  end
end

#folder array
folder = ['app/assets/javascripts/app','app/controllers/', 'app/models/', 'app/helpers/', 'app/mailers/' ]
folder.each do |folder|
  puts 'Working on folder' + folder.to_s
  rbfiles = File.join("../#{folder}**", '*.{rb,coffee}')
  d = Dir.glob(rbfiles)

  d.each  {|fileName|
    puts "Working on #{fileName}"

    #check if file header is present
    checkForHeader(fileName)
  }
end
