Zammad::Application.routes.draw do

  match '/tests-core',            :to => 'tests#core',            :via => :get
  match '/tests-ui',              :to => 'tests#ui',              :via => :get
  match '/tests-model',           :to => 'tests#model',           :via => :get
  match '/tests-model-ui',        :to => 'tests#model_ui',        :via => :get
  match '/tests-form',            :to => 'tests#form',            :via => :get
  match '/tests-form-extended',   :to => 'tests#form_extended',   :via => :get
  match '/tests-form-validation', :to => 'tests#form_validation', :via => :get
  match '/tests-table',           :to => 'tests#table',           :via => :get
  match '/tests-html-utils',      :to => 'tests#html_utils',      :via => :get
  match '/tests/wait/:sec',       :to => 'tests#wait',            :via => :get

end