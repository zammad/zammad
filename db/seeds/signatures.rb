Signature.create_if_not_exists(
  id:            1,
  name:          'default',
  body:          '
  #{user.firstname} #{user.lastname}

--
 Super Support - Waterford Business Park
 5201 Blue Lagoon Drive - 8th Floor & 9th Floor - Miami, 33126 USA
 Email: hot@example.com - Web: http://www.example.com/
--'.text2html,
  updated_by_id: 1,
  created_by_id: 1
)
