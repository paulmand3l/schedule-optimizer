_ = require 'lodash'

chai = require 'chai'
chai.should()

Schedule = require '../src/Schedule'
Evaluator = require '../src/Evaluator'
Mutator = require '../src/Mutator'

alice = 'alice'
bob = 'bob'
charlie = 'charlie'
david = 'david'

describe 'Mutator instance', ->
  it 'should only add to lessons shorter than 2', ->
    mutator = new Mutator []
    for i in [1..100]
      mutator.getMove(['foo', 'bar']).should.not.equal '+'

  it 'should only remove from lessons longer than 1', ->
    mutator = new Mutator []
    for i in [1..100]
      mutator.getMove(['foo']).should.not.equal '-'

  it 'should not suggest an instructor already in the lesson', ->
    mutator = new Mutator new Schedule [[[alice, bob, charlie, david]]]
    for i in [1..100]
      mutator.getInstructorOption([alice], 0, 0).should.not.equal alice

  it 'should mutate the input schedule', ->
    availability = new Schedule [[[alice, bob, charlie, david]]]
    mutator = new Mutator availability
    for i in [1..100]
      schedule = availability.createRandomSchedule()
      mutated = mutator.mutate(schedule)
      _.isEqual(schedule, ).should.not.be.true
