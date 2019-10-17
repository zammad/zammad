Signature.create_if_not_exists(
  id:            1,
  name:          'default',
  body:          '
  #{user.firstname} #{user.lastname}
  
  VIAcode Incident Management System for Azure
  <p>Let VIAcode deal with these alerts & manage your Azure cloud operation for free; <a href="https://www.viacode.com/services/azure-managed-services/?utm_source=product&utm_medium=email&utm_campaign=VIMS&utm_content=passwordchangeemail">activate here</a></p>
--'.text2html,
  updated_by_id: 1,
  created_by_id: 1
)
