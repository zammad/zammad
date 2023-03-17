window.onload = function() {

QUnit.test( "taskbar basic tests", assert => {
  // create task bar div
  $('#qunit').append('<hr><h1>taskbar basic tests</h1><div id="taskbar1"></div>')
  App.TaskManager.init({
    el:           $('#taskbar1'),
    offlineModus: true,
    force:        true,
  })

  // add tasks
  App.TaskManager.execute({
    key:        'TestKey1',
    controller: 'TestController1',
    params:     {
      message: '#1',
    },
    show:       true,
    persistent: false,
  })
  assert.equal($('#qunit .content').length, 1, "check available active contents")
  assert.equal($('#qunit .content.active').length, 1, "check available active contents")
  assert.equal($('#qunit .content.active').text(), "some test controller message:'#1',show:'true',hide:'false',active:'true'", "check active content!")

  // verify
  task = App.TaskManager.get('TestKey1')
  assert.equal(task.notify, false)
  assert.deepEqual(task.state, undefined)
  assert.deepEqual(task.params, { "message": "#1", "shown": true })

  // update
  App.TaskManager.update('TestKey1', { 'state': 'abc' })
  App.TaskManager.update('TestKey1', { 'params': { a: 12 } })
  App.TaskManager.notify('TestKey1')

  // verify
  task = App.TaskManager.get('TestKey1')
  assert.equal(task.notify, true)
  assert.deepEqual(task.state, 'abc')
  assert.deepEqual(task.params, { "a": 12 })

  App.TaskManager.execute({
    key:        'TestKey2',
    controller: 'TestController1',
    params:     {
      message: '#2',
    },
    show:       true,
    persistent: false,
  })
  assert.equal($('#qunit .content').length, 2, "check available active contents")
  assert.equal($('#qunit .content.active').length, 1, "check available active contents")
  assert.equal($('#qunit .content.active').text(), "some test controller message:'#2',show:'true',hide:'false',active:'true'", "check active content!")

  assert.equal($('#qunit #content_permanent_TestKey1').text(), "some test controller message:'#1',show:'true',hide:'true',active:'false'", "check active content!")
  assert.equal($('#qunit #content_permanent_TestKey2').text(), "some test controller message:'#2',show:'true',hide:'false',active:'true'", "check active content!")

  // check task history
  assert.equal(App.TaskManager.nextTaskUrl(), '#/some/url/#2')
  assert.equal(App.TaskManager.nextTaskUrl(), '#/some/url/#1')

  App.TaskManager.execute({
    key:        'TestKey3',
    controller: 'TestController1',
    params:     {
      message: '#3',
    },
    show:       false,
    persistent: false,
  })
  assert.equal($('#qunit .content').length, 2, "check available active contents")
  assert.equal($('#qunit .content.active').length, 1, "check available active contents")
  assert.equal($('#qunit .content.active').text(), "some test controller message:'#2',show:'true',hide:'false',active:'true'")

  assert.equal($('#qunit #content_permanent_TestKey1').text(), "some test controller message:'#1',show:'true',hide:'true',active:'false'", "check active content!")
  assert.equal($('#qunit #content_permanent_TestKey2').text(), "some test controller message:'#2',show:'true',hide:'false',active:'true'", "check active content!")

  App.TaskManager.execute({
    key:        'TestKey3',
    controller: 'TestController1',
    params:     {
      message: '#3',
    },
    show:       true,
    persistent: false,
  })
  assert.equal($('#qunit .content').length, 3, "check available active contents")
  assert.equal($('#qunit .content.active').length, 1, "check available active contents")
  assert.equal($('#qunit .content.active').text(), "some test controller message:'#3',show:'true',hide:'true',active:'true'", "check active content!")

  assert.equal($('#qunit #content_permanent_TestKey1').text(), "some test controller message:'#1',show:'true',hide:'true',active:'false'", "check active content!")
  assert.equal($('#qunit #content_permanent_TestKey2').text(), "some test controller message:'#2',show:'true',hide:'true',active:'false'", "check active content!")
  assert.equal($('#qunit #content_permanent_TestKey3').text(), "some test controller message:'#3',show:'true',hide:'true',active:'true'", "check active content!")

  App.TaskManager.execute({
    key:        'TestKey4',
    controller: 'TestController1',
    params:     {
      message: '#4',
    },
    show:       false,
    persistent: true,
  })
  assert.equal($('#qunit .content').length, 3, "check available active contents")
  assert.equal($('#qunit .content.active').length, 1, "check available active contents")
  assert.equal($('#qunit .content.active').text(), "some test controller message:'#3',show:'true',hide:'true',active:'true'", "check active content!")

  assert.equal($('#qunit #content_permanent_TestKey1').text(), "some test controller message:'#1',show:'true',hide:'true',active:'false'", "check active content!")
  assert.equal($('#qunit #content_permanent_TestKey2').text(), "some test controller message:'#2',show:'true',hide:'true',active:'false'", "check active content!")
  assert.equal($('#qunit #content_permanent_TestKey3').text(), "some test controller message:'#3',show:'true',hide:'true',active:'true'", "check active content!")

  App.TaskManager.execute({
    key:        'TestKey5',
    controller: 'TestController1',
    params:     {
      message: '#5',
    },
    show:       true,
    persistent: true,
  })
  assert.equal($('#qunit .content').length, 4, "check available active contents")
  assert.equal($('#qunit .content.active').length, 1, "check available active contents")
  assert.equal($('#qunit .content.active').text(), "some test controller message:'#5',show:'true',hide:'false',active:'true'")

  assert.equal($('#qunit #content_permanent_TestKey1').text(), "some test controller message:'#1',show:'true',hide:'true',active:'false'", "check active content!")
  assert.equal($('#qunit #content_permanent_TestKey2').text(), "some test controller message:'#2',show:'true',hide:'true',active:'false'", "check active content!")
  assert.equal($('#qunit #content_permanent_TestKey3').text(), "some test controller message:'#3',show:'true',hide:'true',active:'false'", "check active content!")
  assert.equal($('#qunit #content_permanent_TestKey5').text(), "some test controller message:'#5',show:'true',hide:'false',active:'true'", "check active content!")

  App.TaskManager.execute({
    key:        'TestKey6',
    controller: 'TestController1',
    params:     {
      message: '#6',
    },
    show:       true,
    persistent: false,
  })
  assert.equal($('#qunit .content').length, 5, "check available active contents")
  assert.equal($('#qunit .content.active').length, 1, "check available active contents")
  assert.equal($('#qunit .content.active').text(), "some test controller message:'#6',show:'true',hide:'false',active:'true'")

  assert.equal($('#qunit #content_permanent_TestKey1').text(), "some test controller message:'#1',show:'true',hide:'true',active:'false'", "check active content!")
  assert.equal($('#qunit #content_permanent_TestKey2').text(), "some test controller message:'#2',show:'true',hide:'true',active:'false'", "check active content!")
  assert.equal($('#qunit #content_permanent_TestKey3').text(), "some test controller message:'#3',show:'true',hide:'true',active:'false'", "check active content!")
  assert.equal($('#qunit #content_permanent_TestKey5').text(), "some test controller message:'#5',show:'true',hide:'true',active:'false'", "check active content!")
  assert.equal($('#qunit #content_permanent_TestKey6').text(), "some test controller message:'#6',show:'true',hide:'false',active:'true'", "check active content!")

  // remove task#2
  App.TaskManager.remove('TestKey2')

  assert.equal($('#qunit .content').length, 4, "check available active contents")
  assert.equal($('#qunit .content.active').length, 1, "check available active contents")
  assert.equal($('#qunit .content.active').text(), "some test controller message:'#6',show:'true',hide:'false',active:'true'")

  assert.equal($('#qunit #content_permanent_TestKey1').text(), "some test controller message:'#1',show:'true',hide:'true',active:'false'", "check active content!")
  assert.equal($('#qunit #content_permanent_TestKey3').text(), "some test controller message:'#3',show:'true',hide:'true',active:'false'", "check active content!")
  assert.equal($('#qunit #content_permanent_TestKey5').text(), "some test controller message:'#5',show:'true',hide:'true',active:'false'", "check active content!")
  assert.equal($('#qunit #content_permanent_TestKey6').text(), "some test controller message:'#6',show:'true',hide:'false',active:'true'", "check active content!")

  // activate task#3
  App.TaskManager.execute({
    key:        'TestKey3',
    controller: 'TestController1',
    params:     {
      message: '#3',
    },
    show:       true,
    persistent: false,
  })
  assert.equal($('#qunit .content').length, 4, "check available active contents")
  assert.equal($('#qunit .content.active').length, 1, "check available active contents")
  assert.equal($('#qunit .content.active').text(), "some test controller message:'#3',show:'true',hide:'true',active:'true'")

  assert.equal($('#qunit #content_permanent_TestKey1').text(), "some test controller message:'#1',show:'true',hide:'true',active:'false'", "check active content!")
  assert.equal($('#qunit #content_permanent_TestKey3').text(), "some test controller message:'#3',show:'true',hide:'true',active:'true'", "check active content!")
  assert.equal($('#qunit #content_permanent_TestKey5').text(), "some test controller message:'#5',show:'true',hide:'true',active:'false'", "check active content!")
  assert.equal($('#qunit #content_permanent_TestKey6').text(), "some test controller message:'#6',show:'true',hide:'true',active:'false'", "check active content!")


  // activate task#1
  App.TaskManager.execute({
    key:        'TestKey1',
    controller: 'TestController1',
    params:     {
      message: '#1',
    },
    show:       true,
    persistent: false,
  })
  assert.equal($('#qunit .content').length, 4, "check available active contents")
  assert.equal($('#qunit .content.active').length, 1, "check available active contents")
  assert.equal($('#qunit .content.active').text(), "some test controller message:'#1',show:'true',hide:'true',active:'true'")

  assert.equal($('#qunit #content_permanent_TestKey1').text(), "some test controller message:'#1',show:'true',hide:'true',active:'true'", "check active content!")
  assert.equal($('#qunit #content_permanent_TestKey3').text(), "some test controller message:'#3',show:'true',hide:'true',active:'false'", "check active content!")
  assert.equal($('#qunit #content_permanent_TestKey5').text(), "some test controller message:'#5',show:'true',hide:'true',active:'false'", "check active content!")
  assert.equal($('#qunit #content_permanent_TestKey6').text(), "some test controller message:'#6',show:'true',hide:'true',active:'false'", "check active content!")

  // remove task#1
  App.TaskManager.remove('TestKey1')

  // verify if task#3 is active
  assert.equal($('#qunit .content').length, 3, "check available active contents")
  assert.equal($('#qunit .content.active').length, 0, "check available active contents")
  assert.equal($('#qunit .content.active').text(), "")

  // remove task#3
  App.TaskManager.remove('TestKey3')

  // verify if task#5 is active
  assert.equal($('#qunit .content').length, 2, "check available active contents")
  assert.equal($('#qunit .content.active').length, 0, "check available active contents")
  assert.equal($('#qunit .content.active').text(), "")

  // remove task#5 // can not get removed because of permanent task
  App.TaskManager.remove('TestKey5')

  // verify if task#5 is active
  assert.equal($('#qunit .content').length, 2, "check available active contents")
  assert.equal($('#qunit .content.active').length, 0, "check available active contents")
  assert.equal($('#qunit .content.active').text(), "")

  // create task#7
  App.TaskManager.execute({
    key:        'TestKey7',
    controller: 'TestController1',
    params:     {
      message: '#7',
    },
    show:       true,
    persistent: false,
  })
  assert.equal($('#qunit .content').length, 3, "check available active contents")
  assert.equal($('#qunit .content.active').length, 1, "check available active contents")
  assert.equal($('#qunit .content.active').text(), "some test controller message:'#7',show:'true',hide:'false',active:'true'", "check active content!")

  // remove task#7
  App.TaskManager.remove('TestKey7')

  // verify if task#5 is active
  assert.equal($('#qunit .content').length, 2, "check available active contents")
  assert.equal($('#qunit .content.active').length, 0, "check available active contents")
  assert.equal($('#qunit .content.active').text(), "")

  // check task history
  assert.equal(App.TaskManager.nextTaskUrl(), '#/some/url/#6')
  assert.equal(App.TaskManager.nextTaskUrl(), '#/some/url/#5')
  assert.equal(App.TaskManager.nextTaskUrl(), '#/some/url/#6')
  assert.equal(App.TaskManager.nextTaskUrl(), '#/some/url/#6')

  // remove task#6
  App.TaskManager.remove('TestKey6')

  // check task history
  assert.equal(App.TaskManager.nextTaskUrl(), false)
  assert.equal(App.TaskManager.nextTaskUrl(), false)

  // check max tabs
  var times = 5;
  App.TaskManager.tasksAutoCleanupDelayTime(200)
  App.Config.set('ui_task_mananger_max_task_count', 3)

  for(var i=0; i < times; i++){
    App.TaskManager.execute({
      key:        'TestKeyLoop' + i,
      controller: 'TestController1',
      params:     {
        message: "#" + i,
      },
      show:       true,
      persistent: false,
    })
  }
  assert.equal(App.TaskManager.all().length, 5)

})

App.Delay.set(function() {
  QUnit.test( "taskbar check max tabs 2", assert => {

    assert.equal(App.TaskManager.all().length, 3)

    var times = 5;
    for(var i=0; i < times; i++){
      App.TaskManager.execute({
        key:        'TestKeyLoop2' + i,
        controller: 'TestController1',
        params:     {
          message: "#" + i,
          changedState: true
        },
        show:       true,
        persistent: false,
      })
    }
    assert.equal(App.TaskManager.all().length, 8)

  })
}, 1000);

App.Delay.set(function() {
  QUnit.test( "taskbar check max tabs 5", assert => {

    assert.equal(App.TaskManager.all().length, 5)

    // destroy task bar
    App.TaskManager.reset()

    // check if any taskar exists
    assert.equal($('#qunit .content').length, 0, "check available active contents")
  })
}, 2000);

}
