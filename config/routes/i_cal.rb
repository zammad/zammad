Zammad::Application.routes.draw do

  match '/ical',                 to: 'i_cal#all',    via: :get
  match '/ical/:object',         to: 'i_cal#object', via: :get
  match '/ical/:object/:method', to: 'i_cal#object', via: :get
end
