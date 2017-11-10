window.App ||= {}

App.init = ->
  pymChild = new pym.Child()

  $(document).foundation()

  if $('ladda').length
    $('.ladda').ladda('bind')

  # disable children checkboxes
  $('[data-behavior~=form-with-children-checkboxes] input[type=checkbox]').click ->
    childrenCheckboxes = $(document).find('.children[data-for=' + $(this).attr('id') + ']').find('input[type=checkbox]')
    childrenCheckboxes.attr 'disabled', $(this).is(':checked')
    childrenCheckboxes.attr 'checked', $(this).is(':checked')

$(document).on 'turbolinks:load', ->
  App.init()
