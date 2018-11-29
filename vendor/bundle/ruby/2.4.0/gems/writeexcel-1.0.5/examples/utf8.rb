#!/usr/bin/ruby -w
# -*- coding: utf-8 -*-

$debug = true

require 'writeexcel'

workbook = WriteExcel.new('utf8.xls')
worksheet = workbook.add_worksheet('シート１')
format = workbook.add_format(:font => 'ＭＳ 明朝')
worksheet.set_footer('フッター')
worksheet.set_header('ヘッダー')
worksheet.write('A1', 'ＵＴＦ８文字列', format)
worksheet.write('A2', '=CONCATENATE(A1,"の連結")', format)
workbook.close
