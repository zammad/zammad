require 'writeexcel'

  workbook = WriteExcel.new('password_protection.xls')
  worksheet = workbook.add_worksheet

    # Create some format objects
    locked    = workbook.add_format(:locked => 1)
    unlocked  = workbook.add_format(:locked => 0)
    hidden    = workbook.add_format(:hidden => 1)

    # Format the columns
    worksheet.set_column('A:A', 42)
    worksheet.set_selection('B3:B3')

    # Protect the worksheet
    worksheet.protect('password')

    # Examples of cell locking and hiding
    worksheet.write('A1', 'Cell B1 is locked. It cannot be edited.')
    worksheet.write('B1', '=1+2', locked)

    worksheet.write('A2', 'Cell B2 is unlocked. It can be edited.')
    worksheet.write('B2', '=1+2', unlocked)

    worksheet.write('A3', "Cell B3 is hidden. The formula isn't visible.")
    worksheet.write('B3', '=1+2', hidden)

    worksheet.write('A5', 'Use Menu->Tools->Protection->Unprotect Sheet')
    worksheet.write('A6', 'to remove the worksheet protection.   ')
    worksheet.write('A7', 'The password is "password".   ')

    workbook.close
