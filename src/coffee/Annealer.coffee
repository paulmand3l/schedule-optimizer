class Annealer
  constructor: (@steps=1000, @tau=0) ->

  currentTemperature: (i) ->
    return 1 - i / @steps

  acceptanceProbability: (currentScore, alternateScore, currentTemperature) ->
    if alternateScore < currentScore
      return 1
    else
      return Math.exp (currentScore - alternateScore) / currentTemperature

  anneal: (initial, doChange, getScore) ->
    current = initial
    currentScore = getScore initial

    for i in [0..@steps-1]
      # console.log '------- Iteration', i
      alternate = doChange current
      alternateScore = getScore alternate
      # console.log ' ', currentScore, 'vs', alternateScore

      currentTemperature = @currentTemperature i
      acceptanceProbability = @acceptanceProbability currentScore, alternateScore, currentTemperature

      # console.log currentTemperature, acceptanceProbability
      if Math.random() < acceptanceProbability
        # console.log '>> Swapping!'
        current = alternate
        currentScore = alternateScore
        # console.log currentScore

    return current

module.exports = Annealer
