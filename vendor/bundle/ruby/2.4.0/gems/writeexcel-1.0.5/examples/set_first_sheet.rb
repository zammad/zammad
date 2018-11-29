#!/usr/bin/ruby -w
# -*- coding:utf-8 -*-

require 'writeexcel'

workbook = WriteExcel.new('set_first_sheet.xls')
20.times { workbook.add_worksheet }
worksheet21 = workbook.add_worksheet
worksheet22 = workbook.add_worksheet

worksheet21.set_first_sheet
worksheet22.activate
workbook.close
