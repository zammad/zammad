Zammad::Application.routes.draw do

  match '/tests-core',      :to => 'tests#core',  :via => :get
  match '/tests-form',      :to => 'tests#form',  :via => :get
  match '/tests/wait/:sec', :to => 'tests#wait',  :via => :get

end