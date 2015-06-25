Zammad::Application.routes.draw do
  api_path = Rails.configuration.api_path

  match api_path + '/ical',                 to: 'i_cal#all',    via: :get
  match api_path + '/ical/:object',         to: 'i_cal#object', via: :get
  match api_path + '/ical/:object/:method', to: 'i_cal#object', via: :get
end
