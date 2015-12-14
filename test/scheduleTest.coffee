chai = require 'chai'
chai.should()

Schedule = require '../src/coffee/Schedule'

alice = 'alice'
Alice = 'Alice'
alicesmith = 'alice smith'
AliceSmith = 'Alice Smith'
alice_ = 'alice '
aliceq = 'alice?'
bob = 'bob'
charlie = 'charlie'
david = 'david'

describe 'Schedule instance', ->
  it 'should lowercase instructors', ->
    schedule = new Schedule [[[Alice]]], true
    schedule.nights[0][0][0].should.equal alice

  it 'should capitalize correctly', ->
    schedule = new Schedule [[[alicesmith]]], true
    schedule = schedule.capitalize()
    schedule.nights[0][0][0].should.equal AliceSmith

  it 'should trim whitespace from instructors', ->
    schedule = new Schedule [[[alice_]]], true
    schedule.nights[0][0][0].should.equal alice

  it 'should trim question marks from instructors', ->
    schedule = new Schedule [[[aliceq]]], true
    schedule.nights[0][0][0].should.equal alice

  it 'should remove duplicate instructors for the same class', ->
    schedule = new Schedule [[[alice, alice]]]
    schedule.nights[0][0].length.should.equal 1

  it 'should iterate through nights', ->
    instructors = [alice, bob]
    schedule = new Schedule [[instructors]]
    schedule.forEachNight (instructors, i) ->
      instructors.should.equal instructors
      i.should.equal 0

  it 'should iterate through lessons', ->
    schedule = new Schedule [[[alice]], [[bob, charlie]]]
    schedule.forEachLesson (instructors, i, j) ->
      instructors[i].should.equal [alice, charlie][i]
      j.should.equal 0

  it 'should get instructors for a particular lesson on a particular night', ->
    schedule = new Schedule [[[alice]]]
    instructors = schedule.getInstructors(0, 0)
    instructors[0].should.equal alice

  it 'should default to the first lesson when getting instructors', ->
    schedule = new Schedule [[[alice]]]
    instructors = schedule.getInstructors(0, 1)
    instructors[0].should.equal alice

  it 'should count lessons', ->
    schedule = new Schedule [[[alice], [bob]]]
    schedule.lessonCount().should.equal 2

  it 'should count instructors', ->
    schedule = new Schedule [[[alice, bob], [alice, charlie]], [[charlie, bob], [bob, alice]]]
    counts = schedule.instructorCounts()
    counts.alice.should.equal 3
    counts.bob.should.equal 3
    counts.charlie.should.equal 2

  it 'should count maybe instructors (?) as 0.5', ->
    schedule = new Schedule [[[alice, 'bob?']]]
    counts = schedule.instructorCounts()
    counts.alice.should.equal 1
    counts.bob.should.equal 0.5

  it 'should limit the maximum number of instructors', ->
    maxInstructors = 1
    schedule = new Schedule( [[[alice, bob, charlie, david]]] ).createRandomSchedule 1, maxInstructors
    schedule.nights[0][0].length.should.be.at.most maxInstructors
    schedule.nights[0][0].length.should.be.at.least 1

  it 'should create a random schedule', ->
    schedule = new Schedule( [[[alice]]] ).createRandomSchedule 1
    schedule.nights[0][0][0].should.equal alice

