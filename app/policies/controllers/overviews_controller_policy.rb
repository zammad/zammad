class Controllers::OverviewsControllerPolicy < Controllers::ApplicationControllerPolicy
  default_permit!('admin.overview')
end
