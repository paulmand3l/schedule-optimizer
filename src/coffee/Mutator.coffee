Schedule = require './Schedule'

class Mutator
  constructor: (@availability, @maxInstructors=2) ->

  mutate: (nights) ->
    nightIndex = Math.floor Math.random() * nights.length
    night = nights[nightIndex]

    lessonIndex = Math.floor Math.random() * night.length
    lesson = night[lessonIndex]

    move = @getMove lesson

    instructorIndex = Math.floor Math.random() * lesson.length
    instructor = @chooseInstructor lesson, nightIndex, lessonIndex

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
    nights

  getMove: (lesson) ->
    moves = ['~']
    if lesson.length == @maxInstructors
      moves.push '-'
    if lesson.length == 1
      moves.push '+'

    moves[Math.floor(Math.random() * moves.length)]

  chooseInstructor: (lesson, nightIndex, lessonIndex) ->
    instructors = @availability.getInstructors(nightIndex, lessonIndex)
    unchosenInstructors = instructors.filter (instructor) ->
      instructor not in lesson

    unchosenInstructors[Math.floor(Math.random() * unchosenInstructors.length)]


module.exports = Mutator
