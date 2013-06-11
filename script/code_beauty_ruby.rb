#!/usr/bin/ruby -w
=begin
/***************************************************************************
 *   Copyright (C) 2008, Paul Lutus                                        *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.             *
 ***************************************************************************/
=end

PVERSION = "Version 2.9, 10/24/2008"

module RBeautify

   # user-customizable values

   RBeautify::TabStr = " "
   RBeautify::TabSize = 3

   # indent regexp tests

   IndentExp = [
      /^module\b/,
      /^class\b/,
      /^if\b/,
      /(=\s*|^)until\b/,
      /(=\s*|^)for\b/,
      /^unless\b/,
      /(=\s*|^)while\b/,
      /(=\s*|^)begin\b/,
      /(^| )case\b/,
      /\bthen\b/,
      /^rescue\b/,
      /^def\b/,
      /\bdo\b/,
      /^else\b/,
      /^elsif\b/,
      /^ensure\b/,
      /\bwhen\b/,
      /\{[^\}]*$/,
      /\[[^\]]*$/
   ]

   # outdent regexp tests

   OutdentExp = [
      /^rescue\b/,
      /^ensure\b/,
      /^elsif\b/,
      /^end\b/,
      /^else\b/,
      /\bwhen\b/,
      /^[^\{]*\}/,
      /^[^\[]*\]/
   ]

   def RBeautify.rb_make_tab(tab)
      return (tab < 0)?"":TabStr * TabSize * tab
   end

   def RBeautify.rb_add_line(line,tab)
      line.strip!
      line = rb_make_tab(tab) + line if line.length > 0
      return line
   end

   def RBeautify.beautify_string(source, path = "")
      comment_block = false
      in_here_doc = false
      here_doc_term = ""
      program_end = false
      multiLine_array = []
      multiLine_str = ""
      tab = 0
      output = []
      source.each do |line|
         line.chomp!
         if(!program_end)
            # detect program end mark
            if(line =~ /^__END__$/)
               program_end = true
            else
               # combine continuing lines
               if(!(line =~ /^\s*#/) && line =~ /[^\\]\\\s*$/)
                  multiLine_array.push line
                  multiLine_str += line.sub(/^(.*)\\\s*$/,"\\1")
                  next
               end

               # add final line
               if(multiLine_str.length > 0)
                  multiLine_array.push line
                  multiLine_str += line.sub(/^(.*)\\\s*$/,"\\1")
               end

               tline = ((multiLine_str.length > 0)?multiLine_str:line).strip
               if(tline =~ /^=begin/)
                  comment_block = true
               end
               if(in_here_doc)
                  in_here_doc = false if tline =~ %r{\s*#{here_doc_term}\s*}
               else # not in here_doc
                  if tline =~ %r{=\s*<<}
                     here_doc_term = tline.sub(%r{.*=\s*<<-?\s*([_|\w]+).*},"\\1")
                     in_here_doc = here_doc_term.size > 0
                  end
               end
            end
         end
         if(comment_block || program_end || in_here_doc)
            # add the line unchanged
            output << line
         else
            comment_line = (tline =~ /^#/)
            if(!comment_line)
               # throw out sequences that will
               # only sow confusion
               while tline.gsub!(/\{[^\{]*?\}/,"")
               end
               while tline.gsub!(/\[[^\[]*?\]/,"")
               end
               while tline.gsub!(/'.*?'/,"")
               end
               while tline.gsub!(/".*?"/,"")
               end
               while tline.gsub!(/\`.*?\`/,"")
               end
               while tline.gsub!(/\([^\(]*?\)/,"")
               end
               while tline.gsub!(/\/.*?\//,"")
               end
               while tline.gsub!(/%r(.).*?\1/,"")
               end
               # delete end-of-line comments
               tline.sub!(/#[^\"]+$/,"")
               # convert quotes
               tline.gsub!(/\\\"/,"'")
               OutdentExp.each do |re|
                  if(tline =~ re)
                     tab -= 1
                     break
                  end
               end
            end
            if (multiLine_array.length > 0)
               multiLine_array.each do |ml|
                  output << rb_add_line(ml,tab)
               end
               multiLine_array.clear
               multiLine_str = ""
            else
               output << rb_add_line(line,tab)
            end
            if(!comment_line)
               IndentExp.each do |re|
                  if(tline =~ re && !(tline =~ /\s+end\s*$/))
                     tab += 1
                     break
                  end
               end
            end
         end
         if(tline =~ /^=end/)
            comment_block = false
         end
      end
      error = (tab != 0)
      STDERR.puts "Error: indent/outdent mismatch: #{tab}." if error
      return output.join("\n") + "\n",error
   end # beautify_string

   def RBeautify.beautify_file(path)
      error = false
      if(path == '-') # stdin source
         source = STDIN.read
         dest,error = beautify_string(source,"stdin")
         print dest
      else # named file source
         source = File.read(path)
         dest,error = beautify_string(source,path)
         if(source != dest)
            # make a backup copy
            #File.open(path + "~","w") { |f| f.write(source) }
            # overwrite the original
            File.open(path,"w") { |f| f.write(dest) }
         end
      end
      return error
   end # beautify_file

   def RBeautify.main
      error = false
      if(!ARGV[0])
         STDERR.puts "usage: Ruby filenames or \"-\" for stdin."
         exit 0
      end
      ARGV.each do |path|
         error = (beautify_file(path))?true:error
      end
      error = (error)?1:0
      exit error
   end # main
end # module RBeautify

# if launched as a standalone program, not loaded as a module
if __FILE__ == $0
   RBeautify.main
end
