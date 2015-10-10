_ = require 'lodash'

class Schedule
  constructor: (schedule, sanitize) ->
    @schedule = schedule.map (night) =>
      night.map (lesson) =>
        if sanitize
          lesson = @sanitizeInstructors lesson
        _.unique lesson

  sanitizeInstructors: (instructors) ->
    instructors.map (instructor) =>
      @sanitizeInstructor instructor

  sanitizeInstructor: (instructor) ->
    instructor.toLowerCase().replace('?', '').trim()

  forEachNight: (cb) ->
    for night, i in @schedule
      instructors = []
      for lesson in night
        instructors = instructors.concat lesson

      cb? instructors, i

  forEachLesson: (cb) ->
    for night, nightIndex in @schedule
      for lesson, lessonIndex in night
        cb? lesson, nightIndex, lessonIndex

  getInstructors: (nightIndex, lessonIndex, sanitize=true) ->
    night = @schedule[nightIndex]

    if lessonIndex > night.length - 1
      instructors = night[0]
    else
      instructors = night[lessonIndex]

    if sanitize
      return @sanitizeInstructors instructors
    else
      return instructors

  lessonCount: ->
    count = 0
    @forEachLesson -> count++
    return count

  instructorCounts: ->
    counts = {}

    @forEachLesson (instructors) =>
      for instructor in instructors
        ifNecessary = _.endsWith instructor, '?'

        instructor = @sanitizeInstructor instructor

        unless counts[instructor]?
          counts[instructor] = 0

        counts[instructor] += if ifNecessary then 0.5 else 1

    return counts

  createRandomSchedule: (classesPerNight=2, maxInstructors=2) ->
    schedule = for night in @schedule
      for i in [0..classesPerNight-1]
        if night.length == classesPerNight
          availableInstructors = night[i]
        else
          availableInstructors = night[0]

        _.sample availableInstructors, _.random 1, maxInstructors

    new Schedule schedule, true

  toString: ->
    string = @schedule.map (night, i) ->
      lessons = night.map (lesson, j) ->
        "  #{j}: #{lesson.join(' and ')}"
      lessons.unshift "Night #{i}"
      return lessons.join '\n'
    return string.join '\n'


module.exports = Schedule
