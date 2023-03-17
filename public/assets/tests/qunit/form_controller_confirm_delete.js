QUnit.test('App.ControllerConfirmDelete closes with correct safe word', assert => {
  let done = assert.async(1)

  let confirm_modal = new App.ControllerConfirmDelete({
    callback: (modal) => {
      assert.ok(true)
      modal.close()
      done()
    }
  })

  confirm_modal.el.find('[name=sure]').val('DELETE')
  confirm_modal.el.find('.js-submit').click()
});

QUnit.test('App.ControllerConfirmDelete does not proceed without a correct safe word', assert => {
  let confirm_modal = new App.ControllerConfirmDelete()

  confirm_modal.el.find('[name=sure]').val('NNN')
  confirm_modal.el.find('.js-submit').click()
  assert.ok(confirm_modal.el.find('.has-error'))

  confirm_modal.close()
});
