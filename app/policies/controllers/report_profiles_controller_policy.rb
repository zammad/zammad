class Controllers::ReportProfilesControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.report_profile')
end
