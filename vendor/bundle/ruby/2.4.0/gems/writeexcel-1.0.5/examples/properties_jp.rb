#!/usr/bin/ruby -w
# -*- coding: utf-8 -*-

##############################################################################
#
# An example of adding document properties to a WriteExcel file.
#
# reverse('©'), August 2008, John McNamara, jmcnamara@cpan.org
#
# original written in Perl by John McNamara
# converted to Ruby by Hideo Nakamura, cxn03651@msj.biglobe.ne.jp
#
require 'writeexcel'

workbook  = WriteExcel.new('properties_jp.xls')
worksheet = workbook.add_worksheet

workbook.set_properties(
    :title    => 'スプレッドシートの作成例',
    :subject  => 'ファイルのプロパティをセット',
    :author   => '中村英夫',
    :manager  => 'John McNamara',
    :company  => 'Rubygem',
    :category => 'エクセルファイル',
    :keywords => 'エクセル プロパティ UTF-8',
    :comments => 'Rubygem writeexcelで作成'
)

worksheet.set_column('A:A', 50)
worksheet.write('A1', 'メニューのファイル（F)-プロパティ(I)を見てください。')

workbook.close
