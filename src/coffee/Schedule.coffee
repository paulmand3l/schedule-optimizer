class Schedule
  constructor: (nights, sanitize) ->
    @nights = nights.map (lessons) =>
      lessons.map (instructors) =>
        if sanitize
          instructors = @sanitizeInstructors instructors

        seenInstructors = {}
        instructors = instructors.filter (instructor) ->
          firstTime = seenInstructors[instructor]?
          seenInstructors[instructor] = true
          return !firstTime

  sanitizeInstructors: (instructors) ->
    instructors.map (instructor) =>
      @sanitizeInstructor instructor

  sanitizeInstructor: (instructor) ->
    instructor.toLowerCase().replace('?', '').trim()

  forEachNight: (cb) ->
    for night, i in @nights
      instructors = []
      for lesson in night
        instructors = instructors.concat lesson

      cb? instructors, i

  forEachLesson: (cb) ->
    for night, nightIndex in @nights
      for lesson, lessonIndex in night
        cb? lesson, nightIndex, lessonIndex

  getInstructors: (nightIndex, lessonIndex, sanitize=true) ->
    night = @nights[nightIndex]

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
        ifNecessary = instructor[instructor.length-1] is '?'

        instructor = @sanitizeInstructor instructor

        unless counts[instructor]?
          counts[instructor] = 0

        counts[instructor] += if ifNecessary then 0.5 else 1

    return counts

  createRandomSchedule: (classesPerNight=2, maxInstructors=2) ->
    nights = for night in @nights
      for i in [0..classesPerNight-1]
        if night.length == 1
          availableInstructors = night[0]
        else
          availableInstructors = night[i]

        numInstructors = 1 + Math.floor Math.random() * (maxInstructors-1)

        for i in [0..numInstructors-1]
          availableInstructors[Math.floor Math.random() * availableInstructors.length]

    new Schedule nights, true

  toString: ->
    nights = @nights.map (lessons, i) ->
      lessons = lessons.map (instructors, j) ->
        "  #{j}: #{instructors.join(' and ')}"
      lessons.unshift "Night #{i}"
      return lessons.join '\n'
    return nights.join '\n'


module.exports = Schedule
