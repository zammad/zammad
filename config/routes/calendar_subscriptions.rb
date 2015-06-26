Zammad::Application.routes.draw do

  match '/calendar_subscriptions',                 to: 'calendar_subscriptions#all',    via: :get
  match '/calendar_subscriptions/:object',         to: 'calendar_subscriptions#object', via: :get
  match '/calendar_subscriptions/:object/:method', to: 'calendar_subscriptions#object', via: :get
end
