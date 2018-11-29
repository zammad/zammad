#!/usr/bin/ruby -w
# -*- coding: utf-8 -*-
require 'stringio'
#
# magic commentを付与する
#

# カレントディレクトリ以下の.rbファイルパスの配列を返す
def rb_files
  Dir.glob("./**/*\.rb")
end

# カレントディレクトリ以下の.orgファイルパスの配列を返す
def org_files
  Dir.glob("./**/*\.org")
end

# ファイル名を*.orgに変更し、変更後のファイル名を返す
def rename_to_org(file)
  orgfile = change_ext_name(file, 'org')
  File.rename(file, orgfile)
  orgfile
end

# ファイル名の拡張子を変更した際のフルパスを返す（実際の変更はしない）
def change_ext_name(file, new_ext)
  File.join(File.dirname(file), File.basename(file, ".*")) + ".#{new_ext}"
end

# shebang か
def shebang?(line)
  line =~ /^#!.*ruby/ ? true : false
end

# magic_comment か
def magic_comment?(line)
  line =~ /coding[:=]\s*[\w.-]+/ ? true : false
end

def add_magic_comment(input = nil, output = nil)
  input  ||= STDIN
  output ||= STDOUT

  magic_comment = "# -*- coding: utf-8 -*-\n"
  if shebang?(line = input.gets)
    output.write(line)
    if magic_comment?(line = input.gets)
      output.write(line)
    else
      output.write(magic_comment)
      output.write(line)
    end
  elsif magic_comment?(line)
    output.write(line)
  else
    output.write(magic_comment)
    output.write(line)
  end
  while(line = input.gets)
    output.write(line)
  end
end

if $0 == __FILE__

rb_files.each do |file|
  orgfile = rename_to_org(file)
  print("#{file}: renamed to #{orgfile}.\n")
  io = StringIO.new
  File.open(orgfile) do |fin|
    File.open(file, 'w') { |fout| add_magic_comment(fin, fout) }
  end
  print("#{file}: contains magic comment.\n")
end
#
# orgファイルをすべて消すには、以下を有効に。
#
org_files.each { |f| File.unlink(f) }

end
