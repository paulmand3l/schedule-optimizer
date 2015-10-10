_ = require 'lodash'

class Evaluator
  constructor: (options={}) ->
    # Instructors who don't want to work on the same night
    @exclusions = options.exclusions || []

    # Instructors who want to work both classes
    @doubles = options.doubles || []

    # Instructors familiar with the venue
    @seniors = options.seniors || []

    # Instructors new to the venue
    @juniors = options.juniors || []

    # Instructors who don't care about teaching much
    @infrequent = options.infrequent || []

  getDesiredCounts: (schedule, availability) ->
    counts = availability.instructorCounts()

    totalAvailable = _.sum counts
    totalSlots = schedule.lessonCount() * 2

    _.mapValues counts, (count) ->
      return count * totalSlots / totalAvailable

  countsCost: (schedule, availability) ->
    actualCounts = schedule.instructorCounts()
    desiredCounts = @getDesiredCounts schedule, availability

    cost = 0

    for instructor, count of desiredCounts
      if actualCounts[instructor]?
        delta = desiredCounts[instructor] - actualCounts[instructor]
      else
        delta = desiredCounts[instructor]

      if instructor in @seniors
        delta = Math.pow(Math.max(0, delta) - 0.1 * Math.min(0, delta), 2)
      else if instructor in @infrequent
        delta = Math.pow(Math.min(0, delta), 2)
      else
        delta = Math.pow(Math.max(0, delta) - 0.5 * Math.min(0, delta), 2)

      cost += delta

    return cost

  exclusionsCost: (schedule) ->
    cost = 0

    schedule.forEachNight (instructors) =>
      for exclusion in @exclusions
        if exclusion[0] in instructors and exclusion[1] in instructors
          cost += 10

    return cost

  juniorsMismatchCost: (schedule) ->
    cost = 0

    schedule.forEachLesson (instructors) =>
      hasJunior = instructors.some (instructor) => instructor in @juniors
      allJunior = instructors.every (instructor) => instructor in @juniors

      if hasJunior and allJunior
        cost += 1

    return cost

  ifNecessaryCost: (schedule, availability) ->
    cost = 0

    schedule.forEachLesson (instructors, nightIndex, lessonIndex) =>
      availableInstructors = availability.getInstructors nightIndex, lessonIndex, false
      sanitizedInstructors = availability.getInstructors nightIndex, lessonIndex, true

      for instructor in instructors
        continue if instructor not in sanitizedInstructors
        instructorIndex = sanitizedInstructors.indexOf instructor
        if _.endsWith availableInstructors[instructorIndex], '?'
          cost += 0.5

    return cost

  doublesCost: (schedule) ->
    cost = 0

    for night in schedule.schedule
      instructors = []
      for lesson in night
        instructors = instructors.concat lesson

      for instructor in instructors
        inAll = night.every (lesson) =>
          instructor in lesson

        if not inAll
          cost += if instructor in @doubles then 0.5 else 0.01

    return cost


  getCost: (schedule, availability, printSummary=false) ->
    countsCost = @countsCost schedule, availability
    exclusionsCost = @exclusionsCost schedule
    juniorsMismatchCost = @juniorsMismatchCost schedule
    ifNecessaryCost = @ifNecessaryCost schedule, availability
    doublesCost = @doublesCost schedule

    if printSummary
      console.log 'Counts:', countsCost
      console.log 'Exclusions:', exclusionsCost
      console.log 'Junior Mismatch:', juniorsMismatchCost
      console.log 'If Necessary:', ifNecessaryCost
      console.log 'Doubles:', doublesCost

    return countsCost +
      exclusionsCost +
      juniorsMismatchCost +
      ifNecessaryCost +
      doublesCost



module.exports = Evaluator
