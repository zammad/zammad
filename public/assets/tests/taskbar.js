window.onload = function() {

test( "taskbar basic tests", function() {
  // create task bar div
  $('#taskbars').append('<hr><h1>taskbar basic tests</h1><div id="taskbar1"></div>')
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
  equal($('#taskbars .content').length, 1, "check available active contents")
  equal($('#taskbars .content.active').length, 1, "check available active contents")
  equal($('#taskbars .content.active').text(), "some test controller message:'#1',show:'true',hide:'false',active:'true'", "check active content!")

  // verify
  task = App.TaskManager.get('TestKey1')
  equal(task.notify, false)
  deepEqual(task.state, undefined)
  deepEqual(task.params, { "message": "#1", "shown": true })

  // update
  App.TaskManager.update('TestKey1', { 'state': 'abc' })
  App.TaskManager.update('TestKey1', { 'params': { a: 12 } })
  App.TaskManager.notify('TestKey1')

  // verify
  task = App.TaskManager.get('TestKey1')
  equal(task.notify, true)
  deepEqual(task.state, 'abc')
  deepEqual(task.params, { "a": 12 })

  App.TaskManager.execute({
    key:        'TestKey2',
    controller: 'TestController1',
    params:     {
      message: '#2',
    },
    show:       true,
    persistent: false,
  })
  equal($('#taskbars .content').length, 2, "check available active contents")
  equal($('#taskbars .content.active').length, 1, "check available active contents")
  equal($('#taskbars .content.active').text(), "some test controller message:'#2',show:'true',hide:'false',active:'true'", "check active content!")

  equal($('#taskbars #content_permanent_TestKey1').text(), "some test controller message:'#1',show:'true',hide:'true',active:'false'", "check active content!")
  equal($('#taskbars #content_permanent_TestKey2').text(), "some test controller message:'#2',show:'true',hide:'false',active:'true'", "check active content!")

  // check task history
  equal(App.TaskManager.nextTaskUrl(), '#/some/url/#2')
  equal(App.TaskManager.nextTaskUrl(), '#/some/url/#1')

  App.TaskManager.execute({
    key:        'TestKey3',
    controller: 'TestController1',
    params:     {
      message: '#3',
    },
    show:       false,
    persistent: false,
  })
  equal($('#taskbars .content').length, 2, "check available active contents")
  equal($('#taskbars .content.active').length, 1, "check available active contents")
  equal($('#taskbars .content.active').text(), "some test controller message:'#2',show:'true',hide:'false',active:'true'")

  equal($('#taskbars #content_permanent_TestKey1').text(), "some test controller message:'#1',show:'true',hide:'true',active:'false'", "check active content!")
  equal($('#taskbars #content_permanent_TestKey2').text(), "some test controller message:'#2',show:'true',hide:'false',active:'true'", "check active content!")

  App.TaskManager.execute({
    key:        'TestKey3',
    controller: 'TestController1',
    params:     {
      message: '#3',
    },
    show:       true,
    persistent: false,
  })
  equal($('#taskbars .content').length, 3, "check available active contents")
  equal($('#taskbars .content.active').length, 1, "check available active contents")
  equal($('#taskbars .content.active').text(), "some test controller message:'#3',show:'true',hide:'true',active:'true'", "check active content!")

  equal($('#taskbars #content_permanent_TestKey1').text(), "some test controller message:'#1',show:'true',hide:'true',active:'false'", "check active content!")
  equal($('#taskbars #content_permanent_TestKey2').text(), "some test controller message:'#2',show:'true',hide:'true',active:'false'", "check active content!")
  equal($('#taskbars #content_permanent_TestKey3').text(), "some test controller message:'#3',show:'true',hide:'true',active:'true'", "check active content!")

  App.TaskManager.execute({
    key:        'TestKey4',
    controller: 'TestController1',
    params:     {
      message: '#4',
    },
    show:       false,
    persistent: true,
  })
  equal($('#taskbars .content').length, 3, "check available active contents")
  equal($('#taskbars .content.active').length, 1, "check available active contents")
  equal($('#taskbars .content.active').text(), "some test controller message:'#3',show:'true',hide:'true',active:'true'", "check active content!")

  equal($('#taskbars #content_permanent_TestKey1').text(), "some test controller message:'#1',show:'true',hide:'true',active:'false'", "check active content!")
  equal($('#taskbars #content_permanent_TestKey2').text(), "some test controller message:'#2',show:'true',hide:'true',active:'false'", "check active content!")
  equal($('#taskbars #content_permanent_TestKey3').text(), "some test controller message:'#3',show:'true',hide:'true',active:'true'", "check active content!")

  App.TaskManager.execute({
    key:        'TestKey5',
    controller: 'TestController1',
    params:     {
      message: '#5',
    },
    show:       true,
    persistent: true,
  })
  equal($('#taskbars .content').length, 4, "check available active contents")
  equal($('#taskbars .content.active').length, 1, "check available active contents")
  equal($('#taskbars .content.active').text(), "some test controller message:'#5',show:'true',hide:'false',active:'true'")

  equal($('#taskbars #content_permanent_TestKey1').text(), "some test controller message:'#1',show:'true',hide:'true',active:'false'", "check active content!")
  equal($('#taskbars #content_permanent_TestKey2').text(), "some test controller message:'#2',show:'true',hide:'true',active:'false'", "check active content!")
  equal($('#taskbars #content_permanent_TestKey3').text(), "some test controller message:'#3',show:'true',hide:'true',active:'false'", "check active content!")
  equal($('#taskbars #content_permanent_TestKey5').text(), "some test controller message:'#5',show:'true',hide:'false',active:'true'", "check active content!")

  App.TaskManager.execute({
    key:        'TestKey6',
    controller: 'TestController1',
    params:     {
      message: '#6',
    },
    show:       true,
    persistent: false,
  })
  equal($('#taskbars .content').length, 5, "check available active contents")
  equal($('#taskbars .content.active').length, 1, "check available active contents")
  equal($('#taskbars .content.active').text(), "some test controller message:'#6',show:'true',hide:'false',active:'true'")

  equal($('#taskbars #content_permanent_TestKey1').text(), "some test controller message:'#1',show:'true',hide:'true',active:'false'", "check active content!")
  equal($('#taskbars #content_permanent_TestKey2').text(), "some test controller message:'#2',show:'true',hide:'true',active:'false'", "check active content!")
  equal($('#taskbars #content_permanent_TestKey3').text(), "some test controller message:'#3',show:'true',hide:'true',active:'false'", "check active content!")
  equal($('#taskbars #content_permanent_TestKey5').text(), "some test controller message:'#5',show:'true',hide:'true',active:'false'", "check active content!")
  equal($('#taskbars #content_permanent_TestKey6').text(), "some test controller message:'#6',show:'true',hide:'false',active:'true'", "check active content!")

  // remove task#2
  App.TaskManager.remove('TestKey2')

  equal($('#taskbars .content').length, 4, "check available active contents")
  equal($('#taskbars .content.active').length, 1, "check available active contents")
  equal($('#taskbars .content.active').text(), "some test controller message:'#6',show:'true',hide:'false',active:'true'")

  equal($('#taskbars #content_permanent_TestKey1').text(), "some test controller message:'#1',show:'true',hide:'true',active:'false'", "check active content!")
  equal($('#taskbars #content_permanent_TestKey3').text(), "some test controller message:'#3',show:'true',hide:'true',active:'false'", "check active content!")
  equal($('#taskbars #content_permanent_TestKey5').text(), "some test controller message:'#5',show:'true',hide:'true',active:'false'", "check active content!")
  equal($('#taskbars #content_permanent_TestKey6').text(), "some test controller message:'#6',show:'true',hide:'false',active:'true'", "check active content!")

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
  equal($('#taskbars .content').length, 4, "check available active contents")
  equal($('#taskbars .content.active').length, 1, "check available active contents")
  equal($('#taskbars .content.active').text(), "some test controller message:'#3',show:'true',hide:'true',active:'true'")

  equal($('#taskbars #content_permanent_TestKey1').text(), "some test controller message:'#1',show:'true',hide:'true',active:'false'", "check active content!")
  equal($('#taskbars #content_permanent_TestKey3').text(), "some test controller message:'#3',show:'true',hide:'true',active:'true'", "check active content!")
  equal($('#taskbars #content_permanent_TestKey5').text(), "some test controller message:'#5',show:'true',hide:'true',active:'false'", "check active content!")
  equal($('#taskbars #content_permanent_TestKey6').text(), "some test controller message:'#6',show:'true',hide:'true',active:'false'", "check active content!")


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
  equal($('#taskbars .content').length, 4, "check available active contents")
  equal($('#taskbars .content.active').length, 1, "check available active contents")
  equal($('#taskbars .content.active').text(), "some test controller message:'#1',show:'true',hide:'true',active:'true'")

  equal($('#taskbars #content_permanent_TestKey1').text(), "some test controller message:'#1',show:'true',hide:'true',active:'true'", "check active content!")
  equal($('#taskbars #content_permanent_TestKey3').text(), "some test controller message:'#3',show:'true',hide:'true',active:'false'", "check active content!")
  equal($('#taskbars #content_permanent_TestKey5').text(), "some test controller message:'#5',show:'true',hide:'true',active:'false'", "check active content!")
  equal($('#taskbars #content_permanent_TestKey6').text(), "some test controller message:'#6',show:'true',hide:'true',active:'false'", "check active content!")

  // remove task#1
  App.TaskManager.remove('TestKey1')

  // verify if task#3 is active
  equal($('#taskbars .content').length, 3, "check available active contents")
  equal($('#taskbars .content.active').length, 0, "check available active contents")
  equal($('#taskbars .content.active').text(), "")

  // remove task#3
  App.TaskManager.remove('TestKey3')

  // verify if task#5 is active
  equal($('#taskbars .content').length, 2, "check available active contents")
  equal($('#taskbars .content.active').length, 0, "check available active contents")
  equal($('#taskbars .content.active').text(), "")

  // remove task#5 // can not get removed because of permanent task
  App.TaskManager.remove('TestKey5')

  // verify if task#5 is active
  equal($('#taskbars .content').length, 2, "check available active contents")
  equal($('#taskbars .content.active').length, 0, "check available active contents")
  equal($('#taskbars .content.active').text(), "")

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
  equal($('#taskbars .content').length, 3, "check available active contents")
  equal($('#taskbars .content.active').length, 1, "check available active contents")
  equal($('#taskbars .content.active').text(), "some test controller message:'#7',show:'true',hide:'false',active:'true'", "check active content!")

  // remove task#7
  App.TaskManager.remove('TestKey7')

  // verify if task#5 is active
  equal($('#taskbars .content').length, 2, "check available active contents")
  equal($('#taskbars .content.active').length, 0, "check available active contents")
  equal($('#taskbars .content.active').text(), "")

  // check task history
  equal(App.TaskManager.nextTaskUrl(), '#/some/url/#6')
  equal(App.TaskManager.nextTaskUrl(), '#/some/url/#5')
  equal(App.TaskManager.nextTaskUrl(), '#/some/url/#6')
  equal(App.TaskManager.nextTaskUrl(), '#/some/url/#6')

  // remove task#6
  App.TaskManager.remove('TestKey6')

  // check task history
  equal(App.TaskManager.nextTaskUrl(), false)
  equal(App.TaskManager.nextTaskUrl(), false)

  // check max tabs
  var times = 5;
  App.TaskManager.tasksAutoCleanupDelayTime(200)
  App.TaskManager.tasksAutoCleanupTaskMax(3)

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
  equal(App.TaskManager.all().length, 5)

})

App.Delay.set(function() {
  test( "taskbar check max tabs 2", function() {

    equal(App.TaskManager.all().length, 3)

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
    equal(App.TaskManager.all().length, 8)

  })
}, 1000);

App.Delay.set(function() {
  test( "taskbar check max tabs 5", function() {

    equal(App.TaskManager.all().length, 5)

    // destroy task bar
    App.TaskManager.reset()

    // check if any taskar exists
    equal($('#taskbars .content').length, 0, "check available active contents")
  })
}, 2000);

}
