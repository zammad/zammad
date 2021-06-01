# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

Zammad::Application.routes.draw do

  match '/tests_core',                        to: 'tests#core',                       via: :get
  match '/tests_session',                     to: 'tests#session',                    via: :get
  match '/tests_local_storage',               to: 'tests#local_storage',              via: :get
  match '/tests_ui',                          to: 'tests#ui',                         via: :get
  match '/tests_i18n',                        to: 'tests#i18n',                       via: :get
  match '/tests_model',                       to: 'tests#model',                      via: :get
  match '/tests_model_binding',               to: 'tests#model_binding',              via: :get
  match '/tests_model_ui',                    to: 'tests#model_ui',                   via: :get
  match '/tests_model_ticket',                to: 'tests#model_ticket',               via: :get
  match '/tests_form',                        to: 'tests#form',                       via: :get
  match '/tests_form_tree_select',            to: 'tests#form_tree_select',           via: :get
  match '/tests_form_find',                   to: 'tests#form_find',                  via: :get
  match '/tests_form_trim',                   to: 'tests#form_trim',                  via: :get
  match '/tests_form_extended',               to: 'tests#form_extended',              via: :get
  match '/tests_form_timer',                  to: 'tests#form_timer',                 via: :get
  match '/tests_form_color',                  to: 'tests#form_color',                 via: :get
  match '/tests_form_validation',             to: 'tests#form_validation',            via: :get
  match '/tests_form_column_select',          to: 'tests#form_column_select',         via: :get
  match '/tests_form_searchable_select',      to: 'tests#form_searchable_select',     via: :get
  match '/tests_form_autocompletion_ajax',    to: 'tests#form_autocompletion_ajax',   via: :get
  match '/tests_form_ticket_perform_action',  to: 'tests#form_ticket_perform_action', via: :get
  match '/tests_form_sla_times',              to: 'tests#form_sla_times',             via: :get
  match '/tests_form_skip_rendering',         to: 'tests#form_skip_rendering',        via: :get
  match '/tests_form_datetime',               to: 'tests#form_datetime',              via: :get
  match '/tests_table',                       to: 'tests#table',                      via: :get
  match '/tests_table_extended',              to: 'tests#table_extended',             via: :get
  match '/tests_html_utils',                  to: 'tests#html_utils',                 via: :get
  match '/tests_ticket_macro',                to: 'tests#ticket_macro',               via: :get
  match '/tests_ticket_selector',             to: 'tests#ticket_selector',            via: :get
  match '/tests_taskbar',                     to: 'tests#taskbar',                    via: :get
  match '/tests_image_service',               to: 'tests#image_service',              via: :get
  match '/tests_text_module',                 to: 'tests#text_module',                via: :get
  match '/tests_color_object',                to: 'tests#color_object',               via: :get
  match '/tests_kb_video_embeding',           to: 'tests#kb_video_embeding',          via: :get
  match '/tests/wait/:sec',                   to: 'tests#wait',                       via: :get
  match '/tests/raised_exception',            to: 'tests#error_raised_exception',     via: :get

end
