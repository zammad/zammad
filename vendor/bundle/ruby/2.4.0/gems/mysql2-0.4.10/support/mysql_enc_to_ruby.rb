$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'mysql2'

user, pass, host, port = ENV.values_at('user', 'pass', 'host', 'port')

mysql_to_rb = {
  "big5"     => "Big5",
  "dec8"     => "NULL",
  "cp850"    => "CP850",
  "hp8"      => "NULL",
  "koi8r"    => "KOI8-R",
  "latin1"   => "ISO-8859-1",
  "latin2"   => "ISO-8859-2",
  "swe7"     => "NULL",
  "ascii"    => "US-ASCII",
  "ujis"     => "eucJP-ms",
  "sjis"     => "Shift_JIS",
  "hebrew"   => "ISO-8859-8",
  "tis620"   => "TIS-620",
  "euckr"    => "EUC-KR",
  "koi8u"    => "KOI8-R",
  "gb2312"   => "GB2312",
  "greek"    => "ISO-8859-7",
  "cp1250"   => "Windows-1250",
  "gbk"      => "GBK",
  "latin5"   => "ISO-8859-9",
  "armscii8" => "NULL",
  "utf8"     => "UTF-8",
  "ucs2"     => "UTF-16BE",
  "cp866"    => "IBM866",
  "keybcs2"  => "NULL",
  "macce"    => "macCentEuro",
  "macroman" => "macRoman",
  "cp852"    => "CP852",
  "latin7"   => "ISO-8859-13",
  "utf8mb4"  => "UTF-8",
  "cp1251"   => "Windows-1251",
  "utf16"    => "UTF-16",
  "cp1256"   => "Windows-1256",
  "cp1257"   => "Windows-1257",
  "utf32"    => "UTF-32",
  "binary"   => "ASCII-8BIT",
  "geostd8"  => "NULL",
  "cp932"    => "Windows-31J",
  "eucjpms"  => "eucJP-ms",
}

client     = Mysql2::Client.new(:username => user, :password => pass, :host => host, :port => port.to_i)
collations = client.query "SHOW COLLATION", :as => :array
encodings  = Array.new(collations.to_a.last[2].to_i)
encodings_with_nil = Array.new(encodings.size)

collations.each do |collation|
  mysql_col_idx = collation[2].to_i
  rb_enc = mysql_to_rb[collation[1]]
  encodings[mysql_col_idx - 1] = [mysql_col_idx, rb_enc]
end

encodings.each_with_index do |encoding, idx|
  encodings_with_nil[idx] = (encoding || [idx, "NULL"])
end

encodings_with_nil.sort! do |a, b|
  a[0] <=> b[0]
end

encodings_with_nil = encodings_with_nil.map do |encoding|
  name = if encoding.nil? || encoding[1] == 'NULL'
    'NULL'
  else
    "\"#{encoding[1]}\""
  end

  "  #{name}"
end

# start printing output

puts "static const char *mysql2_mysql_enc_to_rb[] = {"
puts encodings_with_nil.join(",\n")
puts "};"
