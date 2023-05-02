# coffeelint: disable=camel_case_classes
class App.UiElement.notification_matrix
  @render: (values) ->

    matrixYAxe =
      create:
        name: __('New Ticket')
      update:
        name: __('Ticket update')
      reminder_reached:
        name: __('Ticket reminder reached')
      escalation:
        name: __('Ticket escalation')

    $( App.view('generic/notification_matrix')( matrixYAxe: matrixYAxe, values: values ) )
