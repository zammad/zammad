# Copyright (C) 2012-2023 Zammad Foundation, https://zammad-foundation.org/

class TemplatesController < ApplicationController
  prepend_before_action { authentication_check && authorize! }

=begin

Format:
JSON

Example:
{
  "id": 1,
  "name": "some template",
  "user_id": null,
  "options": {
    "ticket.title": {
      "value": "some title"
    },
    "ticket.customer_id": {
      "value": "2",
      "value_completion": "Nicole Braun <nicole.braun@zammad.org>"
    }
  },
  "updated_at": "2012-09-14T17:51:53Z",
  "created_at": "2012-09-14T17:51:53Z",
  "updated_by_id": 2,
  "created_by_id": 2
}

=end

=begin

Resource:
GET /api/v1/templates.json

Response:
[
  {
    "id": 1,
    "name": "some_name1",
    ...
  },
  {
    "id": 2,
    "name": "some_name2",
    ...
  }
]

Test:
curl http://localhost/api/v1/templates.json -v -u #{login}:#{password}

=end

  def index
    model_index_render(policy_scope(Template), params)
  end

=begin

Resource:
GET /api/v1/templates/#{id}.json

Response:
{
  "id": 1,
  "name": "name_1",
  ...
}

Test:
curl http://localhost/api/v1/templates/#{id}.json -v -u #{login}:#{password}

=end

  def show
    model_show_render(policy_scope(Template), params)
  end

=begin

Resource:
POST /api/v1/templates.json

Payload:
{
  "name": "some name",
  "options": {
    "ticket.title": {
      "value": "some title"
    },
    "ticket.customer_id": {
      "value": "2",
      "value_completion": "Nicole Braun <nicole.braun@zammad.org>"
    }
  }
}

Response:
{
  "id": 1,
  "name": "some_name",
  ...
}

Test:
curl http://localhost/api/v1/templates.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X POST -d '{"name": "some_name", "options": {"ticket.title": {"value": "some title"},"ticket.customer_id": {"value": "2", "value_completion": "Nicole Braun <nicole.braun@zammad.org>"}}}'

=end

  def create
    template_create_render(params)
  end

=begin

Resource:
PUT /api/v1/templates/{id}.json

Payload:
{
  "name": "some name",
  "options": {
    "ticket.title": {
      "value": "some title"
    },
    "ticket.customer_id": {
      "value": "2",
      "value_completion": "Nicole Braun <nicole.braun@zammad.org>"
    }
  }
}

Response:
{
  "id": 1,
  "name": "some_name",
  ...
}

Test:
curl http://localhost/api/v1/templates/1.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X PUT -d '{"name": "some_name", "options": {"ticket.title": {"value": "some title"},"ticket.customer_id": {"value": "2", "value_completion": "Nicole Braun <nicole.braun@zammad.org>"}}}'

=end

  def update
    template_update_render(params)
  end

=begin

Resource:
DELETE /api/v1/templates/{id}.json

Response:
{}

Test:
curl http://localhost/api/v1/templates.json -v -u #{login}:#{password} -H "Content-Type: application/json" -X DELETE

=end

  def destroy
    model_destroy_render(Template, params)
  end

  private

  def old_options?(options)
    has_new_options = false

    options.each_key do |key|
      if key.starts_with?(%r{(ticket|article)\.})
        has_new_options = true
      end
      break if has_new_options
    end

    !has_new_options
  end

  def migrate_options(options)
    old_options = options.clone
    new_options = {}

    article_attribute_list = %w[body form_id]

    # Implements a compatibility layer for templates, by converting `options` to a newer format:
    #   options: {
    #     'ticket.field_1': { value: 'value_1' },
    #     'ticket.field_2': { value: 'value_2', value_completion: 'value_completion_2' },
    #   }
    old_options.each do |key, value|
      new_key = "ticket.#{key}"

      if article_attribute_list.include?(key)
        new_key = "article.#{key}"
      end

      new_options[new_key] = { value: value }

      if old_options.key?("#{key}_completion")
        new_options[new_key]['value_completion'] = old_options["#{key}_completion"]
        old_options.delete("#{key}_completion")
      end
    end

    new_options
  end

  def template_prepare_params(params)
    clean_params = Template.association_name_to_id_convert(params)
    clean_params = Template.param_cleanup(clean_params, true)

    if Template.included_modules.include?(ChecksCoreWorkflow)
      clean_params[:screen] = 'create'
    end

    if old_options?(clean_params[:options])
      clean_params[:options] = migrate_options(clean_params[:options])
      ActiveSupport::Deprecation.warn 'Usage of the old format for template options with unprefixed keys and simple values is deprecated.'
    end

    clean_params
  end

  def template_create_render(params)
    clean_params = template_prepare_params(params)

    template = Template.new(clean_params)
    template.associations_from_param(params)
    template.save!

    if response_expand?
      render json: template.attributes_with_association_names, status: :created
      return
    end

    if response_full?
      render json: template.class.full(template.id), status: :created
      return
    end

    model_create_render_item(template)
  end

  def template_update_render(params)
    template = Template.find(params[:id])

    clean_params = template_prepare_params(params)

    template.with_lock do
      template.associations_from_param(params)
      template.update!(clean_params)
    end

    if response_expand?
      render json: template.attributes_with_association_names, status: :ok
      return
    end

    if response_full?
      render json: template.class.full(template.id), status: :ok
      return
    end

    model_update_render_item(template)
  end
end
