class UpdateForm < ActiveRecord::Migration
  def up

    Setting.create_if_not_exists(
      title: 'Enable Ticket creation',
      name: 'form_ticket_create',
      area: 'Form::Base',
      description: 'Defines if ticket can get created via web form.',
      options: {
        form: [
          {
            display: '',
            null: true,
            name: 'form_ticket_create',
            tag: 'boolean',
            options: {
              true  => 'yes',
              false => 'no',
            },
          },
        ],
      },
      state: false,
      frontend: false,
    )

  end
end
