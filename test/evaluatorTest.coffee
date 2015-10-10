chai = require 'chai'
chai.should()

Schedule = require '../src/Schedule'
Evaluator = require '../src/Evaluator'

alice = 'alice'
bob = 'bob'
charlie = 'charlie'
david = 'david'

getCost = (_availability, _schedule, costFunction='getCost', evaluatorOptions) ->
  availability = new Schedule _availability
  schedule = new Schedule _schedule || _availability
  evaluator = new Evaluator evaluatorOptions

  evaluator[costFunction] schedule, availability

describe 'Evaluator instance', ->
  it 'should compute goal instructor counts', ->
    evaluator = new Evaluator()

    availability = new Schedule [[[alice, bob, charlie, david]]]
    schedule = new Schedule [[[alice]]]

    evaluator.getDesiredCounts(schedule, availability)[alice].should.equal 0.5

  it 'should cost 0 when schedule matches availability', ->
    getCost([[[alice, bob]]]).should.equal 0

  it 'counts should cost non-zero when instructors are under-scheduled', ->
    getCost(
      [[[alice, bob, charlie, david]]],
      [[[alice]]],
      'countsCost'
    ).should.not.equal 0

  it 'should not care if senior instructors are over-scheduled', ->
    getCost(
      [[[alice, bob]], [[charlie, david]]],
      [[[alice, bob]], [[alice, bob]]],
      'countsCost',
      {seniors: [alice, bob]}
    ).should.be.within 2, 3

  it 'should cost non-zero when exclusions are present', ->
    getCost(
      [[[alice, bob]]],
      [[[alice, bob]]],
      'exclusionsCost',
      {exclusions: [[alice, bob]]}
    ).should.not.equal 0

  it 'should cost non-zero when an instructor is scheduled for an ifNecessary slot', ->
    getCost(
      [[[alice, 'bob?']]],
      [[[alice, bob]]],
      'ifNecessaryCost'
    ).should.be.within 0.5, 1

  it 'should cost non-zero when an instructor is not scheduled for both classes on the same night', ->
    getCost(
      [[[alice, bob]]],
      [[[alice], [bob]]],
      'doublesCost',
      { doubles: [alice] }
    ).should.not.equal 0
