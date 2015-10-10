_ = require 'lodash'

Schedule = require './Schedule'

class Mutator
  constructor: (@availability, @maxInstructors=2) ->

  mutate: (schedule) ->
    schedule = _.cloneDeep schedule.schedule

    nightIndex = _.random 0, schedule.length-1
    night = schedule[nightIndex]

    lessonIndex = _.random 0, night.length-1
    lesson = night[lessonIndex]

    move = @getMove lesson

    instructorIndex = _.random(0, lesson.length-1)
    instructor = @getInstructorOption lesson, nightIndex, lessonIndex

    # console.log 'Night:', nightIndex, 'Lesson:', lessonIndex
    # console.log 'Before:', lesson

    switch move
      when '+'
        # console.log 'Adding', instructor
        lesson.splice 0, 0, instructor
      when '-'
        # console.log 'Removing', lesson[instructorIndex]
        lesson.splice instructorIndex, 1
      when '~'
        # console.log 'Swapping', instructor, 'for', lesson[instructorIndex]
        lesson.splice instructorIndex, 1, instructor

    # console.log 'After:', lesson

    new Schedule schedule, true

  getMove: (lesson) ->
    moves = ['~']
    if lesson.length == @maxInstructors
      moves.push '-'
    if lesson.length == 1
      moves.push '+'

    _.sample moves

  getInstructorOption: (lesson, nightIndex, lessonIndex) ->
    possibleReplacements = @availability.getInstructors(nightIndex, lessonIndex)
    _.pull possibleReplacements, lesson...
    _.sample possibleReplacements


module.exports = Mutator
