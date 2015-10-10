chai = require 'chai'
chai.should()

Schedule = require '../src/Schedule'
Evaluator = require '../src/Evaluator'
Mutator = require '../src/Mutator'
Annealer = require '../src/Annealer'

availability = new Schedule [
  [["Victor Lane?", "Paul Mandel", "Brandon Istenes", "Reeva Bradley?", "Brandi Hoberland"]],
  [["Victor Lane?", "Paul Mandel", "Pejing Lee", "Franz Jundis ?", "Claire Murphy", "Reeva Bradley", "Nicole Trissell", "Brandi Hoberland?"]],
  [["Paul Mandel", "Brandon Istenes", "Pejing Lee", "Franz Jundis ?", "Claire Murphy", "Reeva Bradley", "Nicole Trissell", "Brandi Hoberland"]],
  [["Victor Lane?", "Paul Mandel", "Brandon Istenes", "Franz Jundis ?", "Claire Murphy?", "Reeva Bradley", "Nicole Trissell", "Brandi Hoberland"]]
]

mutator = new Mutator availability
evaluator = new Evaluator
  seniors: ['paul mandel', 'nicole trissell', 'reeva bradley']
  juniors: ['claire murphy', 'franz jundis', 'pejing lee', 'brandi hoberland', 'brandon istenes']
  infrequent: ['victor lane']
  exclusions: [['brandon istenes', 'nicole trissell']]
  doubles: ['nicole trissell', 'reeva bradley']

describe 'Annealer instance', ->
  it 'should work', ->
    annealer = new Annealer 1000

    initialSchedule = availability.createRandomSchedule()

    bestSchedule = annealer.anneal initialSchedule, (schedule) ->
      mutator.mutate schedule
    , (schedule) ->
      evaluator.getCost schedule, availability

    console.log bestSchedule.toString()

    evaluator.getCost bestSchedule, availability, true

    actualCounts = bestSchedule.instructorCounts()
    desiredCounts = evaluator.getDesiredCounts bestSchedule, availability

    for instructor, count of desiredCounts
      console.log instructor, count, actualCounts[instructor]
