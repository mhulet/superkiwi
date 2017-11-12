window.App ||= {}

App.init = ->
  $(document).foundation()

  Ladda.bind('.ladda')

  # disable children checkboxes
  $('[data-behavior~=form-with-children-checkboxes] input[type=checkbox]').click ->
    childrenCheckboxes = $(document).find('.children[data-for=' + $(this).attr('id') + ']').find('input[type=checkbox]')
    childrenCheckboxes.prop 'checked', $(this).is(':checked')
    childrenCheckboxes.prop 'disabled', $(this).is(':checked')

  $('[data-behavior~=form-with-children-checkboxes] input[type=checkbox]:checked').each ->
    childrenCheckboxes = $(document).find('.children[data-for=' + $(this).attr('id') + ']').find('input[type=checkbox]')
    childrenCheckboxes.prop 'checked', $(this).is(':checked')
    childrenCheckboxes.prop 'disabled', $(this).is(':checked')

$(document).on 'turbolinks:load', ->
  App.init()
