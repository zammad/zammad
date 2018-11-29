mysql_to_rb = {
  "big5"     => "Big5",
  "dec8"     => nil,
  "cp850"    => "CP850",
  "hp8"      => nil,
  "koi8r"    => "KOI8-R",
  "latin1"   => "ISO-8859-1",
  "latin2"   => "ISO-8859-2",
  "swe7"     => nil,
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
  "armscii8" => nil,
  "utf8"     => "UTF-8",
  "ucs2"     => "UTF-16BE",
  "cp866"    => "IBM866",
  "keybcs2"  => nil,
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
  "geostd8"  => nil,
  "cp932"    => "Windows-31J",
  "eucjpms"  => "eucJP-ms",
}

puts <<-header
%readonly-tables
%enum
%define lookup-function-name mysql2_mysql_enc_name_to_rb
%define hash-function-name mysql2_mysql_enc_name_to_rb_hash
%struct-type
struct mysql2_mysql_enc_name_to_rb_map { const char *name; const char *rb_name; }
%%
header

mysql_to_rb.each do |mysql, ruby|
  if ruby.nil?
    name = "NULL"
  else
    name = "\"#{ruby}\""
  end

  puts "#{mysql}, #{name}"
end
