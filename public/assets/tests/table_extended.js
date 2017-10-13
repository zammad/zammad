// initial list
test('table new - initial list', function() {
  App.i18n.set('de-de')

  $('#table').append('<hr><h1>table with data</h1><div id="table-new1"></div>')
  var el = $('#table-new1')

  App.TicketPriority.refresh([
    {
      id:         1,
      name:       '1 low',
      note:       'some note 1',
      active:     true,
      created_at: '2014-06-10T11:17:34.000Z',
    },
    {
      id:         2,
      name:       '2 normal',
      note:       'some note 2',
      active:     false,
      created_at: '2014-06-10T10:17:34.000Z',
    },
  ], {clear: true})

  var table = new App.ControllerTable({
    el:                 el,
    overviewAttributes: ['name', 'created_at', 'active'],
    model:              App.TicketPriority,
    objects:            App.TicketPriority.search({sortBy:'name', order: 'ASC'}),
    checkbox:           false,
    radio:              false,
  })
  //equal(el.find('table').length, 0, 'row count')
  //table.render()
  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 3, 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), '1 niedrig', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(3)').text().trim(), 'true', 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 3, 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:first').text().trim(), '2 normal', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 2')
  equal(el.find('tbody > tr:nth-child(3) > td').length, 0, 'check row 3')

  result = table.update({sync: true, objects: App.TicketPriority.search({sortBy:'name', order: 'ASC'})})
  equal(result[0], 'noChanges')

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 3, 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), '1 niedrig', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(3)').text().trim(), 'true', 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 3, 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:first').text().trim(), '2 normal', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 2')

  App.TicketPriority.refresh([
    {
      id:         1,
      name:       'Priority',
      note:       'some note 1',
      active:     true,
      created_at: '2014-06-10T11:17:34.000Z',
    },
  ], {clear: true})

  result = table.update({sync: true, objects: App.TicketPriority.search({sortBy:'name', order: 'ASC'})})
  equal(result[0], 'fullRender.lenghtChanged')
  equal(result[1], 2)
  equal(result[2], 1)

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 3, 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), 'Priorität', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(3)').text().trim(), 'true', 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 0, 'check row 2')

  App.TicketPriority.refresh([], {clear: true})

  result = table.update({sync: true, objects: App.TicketPriority.search({sortBy:'name', order: 'ASC'})})
  equal(result[0], 'emptyList')

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Keine Einträge', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 0, 'check row 1')

  App.TicketPriority.refresh([
    {
      id:         1,
      name:       '1 low',
      note:       'some note 1',
      active:     true,
      created_at: '2014-06-10T11:17:34.000Z',
    },
    {
      id:         2,
      name:       '2 normal',
      note:       'some note 2',
      active:     false,
      created_at: '2014-06-10T10:17:34.000Z',
    },
  ], {clear: true})

  result = table.update({sync: true, objects: App.TicketPriority.search({sortBy:'name', order: 'ASC'})})
  equal(result[0], 'fullRender')

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 3, 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), '1 niedrig', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(3)').text().trim(), 'true', 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 3, 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:first').text().trim(), '2 normal', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 2')
  equal(el.find('tbody > tr:nth-child(3) > td').length, 0, 'check row 3')

  App.TicketPriority.refresh([
    {
      id:         1,
      name:       '1 low',
      note:       'some note 1',
      active:     true,
      created_at: '2014-06-10T11:17:34.000Z',
    },
    {
      id:         2,
      name:       '2 normal',
      note:       'some note 2',
      active:     false,
      created_at: '2014-06-10T10:17:34.000Z',
    },
    {
      id:         3,
      name:       '3 high',
      note:       'some note 3',
      active:     false,
      created_at: '2014-06-10T10:17:38.000Z',
    },
  ], {clear: true})

  result = table.update({sync: true, objects: App.TicketPriority.search({sortBy:'name', order: 'ASC'})})
  equal(result[0], 'fullRender.lenghtChanged')
  equal(result[1], 2)
  equal(result[2], 3)

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 3, 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), '1 niedrig', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(3)').text().trim(), 'true', 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 3, 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:first').text().trim(), '2 normal', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 2')
  equal(el.find('tbody > tr:nth-child(3) > td').length, 3, 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:first').text().trim(), '3 hoch', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 3')
  equal(el.find('tbody > tr:nth-child(4) > td').length, 0, 'check row 4')

  result = table.update({sync: true, orderDirection: 'DESC', orderBy: 'name'})
  equal(result[0], 'fullRender.contentChanged')
  equal(result[1], 0)

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 3, 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), '3 hoch', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 3, 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:first').text().trim(), '2 normal', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 2')
  equal(el.find('tbody > tr:nth-child(3) > td').length, 3, 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:first').text().trim(), '1 niedrig', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(3)').text().trim(), 'true', 'check row 3')
  equal(el.find('tbody > tr:nth-child(4) > td').length, 0, 'check row 4')

  result = table.update({sync: true, orderDirection: 'ASC', orderBy: 'name'})
  equal(result[0], 'fullRender.contentChanged')
  equal(result[1], 0)

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 3, 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), '1 niedrig', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(3)').text().trim(), 'true', 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 3, 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:first').text().trim(), '2 normal', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 2')
  equal(el.find('tbody > tr:nth-child(3) > td').length, 3, 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:first').text().trim(), '3 hoch', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 3')
  equal(el.find('tbody > tr:nth-child(4) > td').length, 0, 'check row 4')

  App.TicketPriority.refresh([
    {
      id:         1,
      name:       '1 low',
      note:       'some note 1',
      active:     true,
      created_at: '2014-06-10T11:17:34.000Z',
    },
    {
      id:         3,
      name:       '3 high',
      note:       'some note 3',
      active:     false,
      created_at: '2014-06-10T10:17:38.000Z',
    },
  ], {clear: true})

  result = table.update({sync: true, objects: App.TicketPriority.search({sortBy:'name', order: 'ASC'})})
  equal(result[0], 'fullRender.contentRemoved')
  equal(result[1], 1)
  notOk(result[2])

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 3, 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), '1 niedrig', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(3)').text().trim(), 'true', 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 3, 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:first').text().trim(), '3 hoch', 'check row 3')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td').length, 0, 'check row 3')

  result = table.update({sync: true, overviewAttributes: ['name', 'created_at']})
  equal(result[0], 'fullRender.overviewAttributesChanged')

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th').length, 2, 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 2, 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), '1 niedrig', 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 2, 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:first').text().trim(), '3 hoch', 'check row 3')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td').length, 0, 'check row 3')

  App.TicketPriority.refresh([], {clear: true})

  result = table.update({sync: true, objects: App.TicketPriority.search({sortBy:'name', order: 'ASC'})})
  equal(result[0], 'emptyList')

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Keine Einträge', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 0, 'check row 1')

  App.TicketPriority.refresh([
    {
      id:         1,
      name:       '1 low',
      note:       'some note 1',
      active:     true,
      created_at: '2014-06-10T11:17:34.000Z',
    },
    {
      id:         3,
      name:       '3 high',
      note:       'some note 3',
      active:     false,
      created_at: '2014-06-10T10:17:38.000Z',
    },
  ], {clear: true})

  result = table.update({sync: true, objects: App.TicketPriority.search({sortBy:'name', order: 'ASC'}), overviewAttributes: ['name'], orderBy: 'created_at', orderDirection: 'DESC'})
  equal(result[0], 'fullRender')

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th').length, 1, 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 1, 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), '1 niedrig', 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 1, 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:first').text().trim(), '3 hoch', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td').length, 0, 'check row 3')

  result = table.update({sync: true, objects: App.TicketPriority.search({sortBy:'name', order: 'ASC'}), overviewAttributes: ['name'], orderBy: 'created_at', orderDirection: 'ASC'})
  equal(result[0], 'fullRender.overviewAttributesChanged')

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th').length, 1, 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 1, 'check row 2')
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), '3 hoch', 'check row 3')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 1, 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td:first').text().trim(), '1 niedrig', 'check row 1')
  equal(el.find('tbody > tr:nth-child(3) > td').length, 0, 'check row 3')


  $('#table').append('<hr><h1>table group by with data</h1><div id="table-new2"></div>')
  var el = $('#table-new2')

  App.TicketPriority.refresh([
    {
      id:         1,
      name:       '1 low',
      note:       'some note',
      active:     true,
      created_at: '2014-06-10T11:17:34.000Z',
    },
    {
      id:         2,
      name:       '2 normal',
      note:       'some note',
      active:     true,
      created_at: '2014-06-10T10:17:30.000Z',
    },
    {
      id:         3,
      name:       '3 high',
      note:       'some other note',
      active:     true,
      created_at: '2014-06-10T10:17:38.000Z',
    },
  ], {clear: true})

  var table = new App.ControllerTable({
    el:                 el,
    overviewAttributes: ['name', 'created_at', 'active'],
    model:              App.TicketPriority,
    objects:            App.TicketPriority.search({sortBy:'name', order: 'ASC'}),
    checkbox:           false,
    radio:              false,
    groupBy:            'note',
  })

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 1, 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), 'some note', 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 3, 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:first').text().trim(), '1 niedrig', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(3)').text().trim(), 'true', 'check row 2')
  equal(el.find('tbody > tr:nth-child(3) > td').length, 3, 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:first').text().trim(), '2 normal', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(3)').text().trim(), 'true', 'check row 3')
  equal(el.find('tbody > tr:nth-child(4) > td').length, 1, 'check row 3')
  equal(el.find('tbody > tr:nth-child(4) > td:first').text().trim(), 'some other note', 'check row 3')
  equal(el.find('tbody > tr:nth-child(5) > td:first').text().trim(), '3 hoch', 'check row 5')
  equal(el.find('tbody > tr:nth-child(5) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 5')
  equal(el.find('tbody > tr:nth-child(5) > td:nth-child(3)').text().trim(), 'true', 'check row 5')
  equal(el.find('tbody > tr:nth-child(6) > td').length, 0, 'check row 6')

  result = table.update({sync: true, objects: App.TicketPriority.search({sortBy:'name', order: 'ASC'})})
  equal(result[0], 'noChanges')

  App.TicketPriority.refresh([
    {
      id:         1,
      name:       '1 low',
      note:       'some note',
      active:     true,
      created_at: '2014-06-10T11:17:34.000Z',
    },
    {
      id:         2,
      name:       '2 normal',
      note:       'some note',
      active:     true,
      created_at: '2014-06-10T10:17:30.000Z',
    },
  ], {clear: true})

  result = table.update({sync: true, objects: App.TicketPriority.search({sortBy:'name', order: 'ASC'})})
  equal(result[0], 'fullRender.contentRemoved')

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 1, 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), 'some note', 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 3, 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:first').text().trim(), '1 niedrig', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(3)').text().trim(), 'true', 'check row 2')
  equal(el.find('tbody > tr:nth-child(3) > td').length, 3, 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:first').text().trim(), '2 normal', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(3)').text().trim(), 'true', 'check row 3')
  equal(el.find('tbody > tr:nth-child(4) > td').length, 0, 'check row 6')

  App.TicketPriority.refresh([
    {
      id:         1,
      name:       '1 low',
      note:       'some note',
      active:     true,
      created_at: '2014-06-10T11:17:34.000Z',
    },
    {
      id:         2,
      name:       '2 normal',
      note:       'some note',
      active:     true,
      created_at: '2014-06-10T10:17:30.000Z',
    },
    {
      id:         3,
      name:       '3 high',
      note:       'some other note',
      active:     true,
      created_at: '2014-06-10T10:17:38.000Z',
    },
  ], {clear: true})

  result = table.update({sync: true, objects: App.TicketPriority.search({sortBy:'name', order: 'ASC'})})
  equal(result[0], 'fullRender.lenghtChanged')

  equal(el.find('table > thead > tr').length, 1, 'row count')
  equal(el.find('table > thead > tr > th:nth-child(1)').text().trim(), 'Name', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(2)').text().trim(), 'Erstellt', 'check header')
  equal(el.find('table > thead > tr > th:nth-child(3)').text().trim(), 'Aktiv', 'check header')
  equal(el.find('tbody > tr:nth-child(1) > td').length, 1, 'check row 1')
  equal(el.find('tbody > tr:nth-child(1) > td:first').text().trim(), 'some note', 'check row 1')
  equal(el.find('tbody > tr:nth-child(2) > td').length, 3, 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:first').text().trim(), '1 niedrig', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 2')
  equal(el.find('tbody > tr:nth-child(2) > td:nth-child(3)').text().trim(), 'true', 'check row 2')
  equal(el.find('tbody > tr:nth-child(3) > td').length, 3, 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:first').text().trim(), '2 normal', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 3')
  equal(el.find('tbody > tr:nth-child(3) > td:nth-child(3)').text().trim(), 'true', 'check row 3')
  equal(el.find('tbody > tr:nth-child(4) > td').length, 1, 'check row 3')
  equal(el.find('tbody > tr:nth-child(4) > td:first').text().trim(), 'some other note', 'check row 3')
  equal(el.find('tbody > tr:nth-child(5) > td:first').text().trim(), '3 hoch', 'check row 5')
  equal(el.find('tbody > tr:nth-child(5) > td:nth-child(2)').text().trim(), '10.06.2014', 'check row 5')
  equal(el.find('tbody > tr:nth-child(5) > td:nth-child(3)').text().trim(), 'true', 'check row 5')
  equal(el.find('tbody > tr:nth-child(6) > td').length, 0, 'check row 6')

})
