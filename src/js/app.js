var Annealer, Evaluator, Mutator, Schedule,
  indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

Annealer = (function() {
  function Annealer(steps, tau) {
    this.steps = steps != null ? steps : 1000;
    this.tau = tau != null ? tau : 0;
  }

  Annealer.prototype.currentTemperature = function(i) {
    return 1 - i / this.steps;
  };

  Annealer.prototype.acceptanceProbability = function(currentScore, alternateScore, currentTemperature) {
    if (alternateScore < currentScore) {
      return 1;
    } else {
      return Math.exp((currentScore - alternateScore) / currentTemperature);
    }
  };

  Annealer.prototype.anneal = function(initial, doChange, getScore) {
    var acceptanceProbability, alternate, alternateScore, current, currentScore, currentTemperature, i, k, ref;
    current = initial;
    currentScore = getScore(initial);
    for (i = k = 0, ref = this.steps - 1; 0 <= ref ? k <= ref : k >= ref; i = 0 <= ref ? ++k : --k) {
      alternate = doChange(current);
      alternateScore = getScore(alternate);
      currentTemperature = this.currentTemperature(i);
      acceptanceProbability = this.acceptanceProbability(currentScore, alternateScore, currentTemperature);
      if (Math.random() < acceptanceProbability) {
        current = alternate;
        currentScore = alternateScore;
      }
    }
    return current;
  };

  return Annealer;

})();



Evaluator = (function() {
  function Evaluator(options) {
    if (options == null) {
      options = {};
    }
    this.exclusions = options.exclusions || [];
    this.doubles = options.doubles || [];
    this.seniors = options.seniors || [];
    this.juniors = options.juniors || [];
    this.infrequent = options.infrequent || [];
  }

  Evaluator.prototype.getDesiredCounts = function(schedule, availability) {
    var count, counts, instructor, instructorCounts, output, totalAvailable, totalSlots;
    instructorCounts = availability.instructorCounts();
    counts = Object.keys(instructorCounts).map(function(i) {
      return instructorCounts[i];
    });
    totalAvailable = counts.reduce((function(a, b) {
      return a + b;
    }), 0);
    totalSlots = schedule.lessonCount() * 2;
    output = {};
    for (instructor in instructorCounts) {
      count = instructorCounts[instructor];
      output[instructor] = count * totalSlots / totalAvailable;
    }
    return output;
  };

  Evaluator.prototype.countsCost = function(schedule, availability) {
    var actualCounts, cost, count, delta, desiredCounts, instructor;
    actualCounts = schedule.instructorCounts();
    desiredCounts = this.getDesiredCounts(schedule, availability);
    cost = 0;
    for (instructor in desiredCounts) {
      count = desiredCounts[instructor];
      if (actualCounts[instructor] != null) {
        delta = desiredCounts[instructor] - actualCounts[instructor];
      } else {
        delta = desiredCounts[instructor];
      }
      if (indexOf.call(this.seniors, instructor) >= 0) {
        delta = Math.pow(Math.max(0, delta) - 0.1 * Math.min(0, delta), 2);
      } else if (indexOf.call(this.infrequent, instructor) >= 0) {
        delta = Math.pow(Math.min(0, delta), 2);
      } else {
        delta = Math.pow(Math.max(0, delta) - 0.5 * Math.min(0, delta), 2);
      }
      cost += delta;
    }
    return cost;
  };

  Evaluator.prototype.exclusionsCost = function(schedule) {
    var cost;
    cost = 0;
    schedule.forEachNight((function(_this) {
      return function(instructors) {
        var exclusion, k, len, ref, ref1, ref2, results;
        ref = _this.exclusions;
        results = [];
        for (k = 0, len = ref.length; k < len; k++) {
          exclusion = ref[k];
          if ((ref1 = exclusion[0], indexOf.call(instructors, ref1) >= 0) && (ref2 = exclusion[1], indexOf.call(instructors, ref2) >= 0)) {
            results.push(cost += 10);
          } else {
            results.push(void 0);
          }
        }
        return results;
      };
    })(this));
    return cost;
  };

  Evaluator.prototype.juniorsMismatchCost = function(schedule) {
    var cost;
    cost = 0;
    schedule.forEachLesson((function(_this) {
      return function(instructors) {
        var allJunior, hasJunior;
        hasJunior = instructors.some(function(instructor) {
          return indexOf.call(_this.juniors, instructor) >= 0;
        });
        allJunior = instructors.every(function(instructor) {
          return indexOf.call(_this.juniors, instructor) >= 0;
        });
        if (hasJunior && allJunior) {
          return cost += 1;
        }
      };
    })(this));
    return cost;
  };

  Evaluator.prototype.ifNecessaryCost = function(schedule, availability) {
    var cost;
    cost = 0;
    schedule.forEachLesson((function(_this) {
      return function(instructors, nightIndex, lessonIndex) {
        var availableInstructors, instructor, instructorIndex, k, len, originalInstructor, results, sanitizedInstructors;
        availableInstructors = availability.getInstructors(nightIndex, lessonIndex, false);
        sanitizedInstructors = availability.getInstructors(nightIndex, lessonIndex, true);
        results = [];
        for (k = 0, len = instructors.length; k < len; k++) {
          instructor = instructors[k];
          if (indexOf.call(sanitizedInstructors, instructor) < 0) {
            continue;
          }
          instructorIndex = sanitizedInstructors.indexOf(instructor);
          originalInstructor = availableInstructors[instructorIndex];
          if (originalInstructor[originalInstructor.length - 1] === '?') {
            results.push(cost += 0.5);
          } else {
            results.push(void 0);
          }
        }
        return results;
      };
    })(this));
    return cost;
  };

  Evaluator.prototype.doublesCost = function(schedule) {
    var cost, inAll, instructor, instructors, k, l, len, len1, len2, lesson, m, night, ref;
    cost = 0;
    ref = schedule.nights;
    for (k = 0, len = ref.length; k < len; k++) {
      night = ref[k];
      instructors = [];
      for (l = 0, len1 = night.length; l < len1; l++) {
        lesson = night[l];
        instructors = instructors.concat(lesson);
      }
      for (m = 0, len2 = instructors.length; m < len2; m++) {
        instructor = instructors[m];
        inAll = night.every((function(_this) {
          return function(lesson) {
            return indexOf.call(lesson, instructor) >= 0;
          };
        })(this));
        if (!inAll) {
          cost += indexOf.call(this.doubles, instructor) >= 0 ? 0.5 : 0.01;
        }
      }
    }
    return cost;
  };

  Evaluator.prototype.getCost = function(schedule, availability, details) {
    var countsCost, doublesCost, exclusionsCost, ifNecessaryCost, juniorsMismatchCost, total;
    if (details == null) {
      details = false;
    }
    countsCost = this.countsCost(schedule, availability);
    exclusionsCost = this.exclusionsCost(schedule);
    juniorsMismatchCost = this.juniorsMismatchCost(schedule);
    ifNecessaryCost = this.ifNecessaryCost(schedule, availability);
    doublesCost = this.doublesCost(schedule);
    total = countsCost + exclusionsCost + juniorsMismatchCost + ifNecessaryCost + doublesCost;
    if (details) {
      return {
        total: total,
        countsCost: countsCost,
        exclusionsCost: exclusionsCost,
        juniorsMismatchCost: juniorsMismatchCost,
        ifNecessaryCost: ifNecessaryCost,
        doublesCost: doublesCost
      };
    } else {
      return total;
    }
  };

  return Evaluator;

})();





Mutator = (function() {
  function Mutator(availability1, maxInstructors1) {
    this.availability = availability1;
    this.maxInstructors = maxInstructors1 != null ? maxInstructors1 : 2;
  }

  Mutator.prototype.mutate = function(nights) {
    var instructor, instructorIndex, lesson, lessonIndex, move, night, nightIndex;
    nightIndex = Math.floor(Math.random() * nights.length);
    night = nights[nightIndex];
    lessonIndex = Math.floor(Math.random() * night.length);
    lesson = night[lessonIndex];
    move = this.getMove(lesson);
    instructorIndex = Math.floor(Math.random() * lesson.length);
    instructor = this.chooseInstructor(lesson, nightIndex, lessonIndex);
    switch (move) {
      case '+':
        lesson.splice(0, 0, instructor);
        break;
      case '-':
        lesson.splice(instructorIndex, 1);
        break;
      case '~':
        lesson.splice(instructorIndex, 1, instructor);
    }
    return nights;
  };

  Mutator.prototype.getMove = function(lesson) {
    var moves;
    moves = ['~'];
    if (lesson.length === this.maxInstructors) {
      moves.push('-');
    }
    if (lesson.length === 1) {
      moves.push('+');
    }
    return moves[Math.floor(Math.random() * moves.length)];
  };

  Mutator.prototype.chooseInstructor = function(lesson, nightIndex, lessonIndex) {
    var instructors, unchosenInstructors;
    instructors = this.availability.getInstructors(nightIndex, lessonIndex);
    unchosenInstructors = instructors.filter(function(instructor) {
      return indexOf.call(lesson, instructor) < 0;
    });
    return unchosenInstructors[Math.floor(Math.random() * unchosenInstructors.length)];
  };

  return Mutator;

})();



Schedule = (function() {
  function Schedule(nights, sanitize) {
    this.nights = nights.map((function(_this) {
      return function(lessons) {
        return lessons.map(function(instructors) {
          var seenInstructors;
          if (sanitize) {
            instructors = _this.sanitizeInstructors(instructors);
          }
          seenInstructors = {};
          return instructors = instructors.filter(function(instructor) {
            var firstTime;
            firstTime = seenInstructors[instructor] != null;
            seenInstructors[instructor] = true;
            return !firstTime;
          });
        });
      };
    })(this));
  }

  Schedule.prototype.sanitizeInstructors = function(instructors) {
    return instructors.map((function(_this) {
      return function(instructor) {
        return _this.sanitizeInstructor(instructor);
      };
    })(this));
  };

  Schedule.prototype.sanitizeInstructor = function(instructor) {
    return instructor.toLowerCase().replace('?', '').trim();
  };

  Schedule.prototype.forEachNight = function(cb) {
    var i, instructors, k, l, len, len1, lesson, night, ref, results;
    ref = this.nights;
    results = [];
    for (i = k = 0, len = ref.length; k < len; i = ++k) {
      night = ref[i];
      instructors = [];
      for (l = 0, len1 = night.length; l < len1; l++) {
        lesson = night[l];
        instructors = instructors.concat(lesson);
      }
      results.push(typeof cb === "function" ? cb(instructors, i) : void 0);
    }
    return results;
  };

  Schedule.prototype.forEachLesson = function(cb) {
    var k, len, lesson, lessonIndex, night, nightIndex, ref, results;
    ref = this.nights;
    results = [];
    for (nightIndex = k = 0, len = ref.length; k < len; nightIndex = ++k) {
      night = ref[nightIndex];
      results.push((function() {
        var l, len1, results1;
        results1 = [];
        for (lessonIndex = l = 0, len1 = night.length; l < len1; lessonIndex = ++l) {
          lesson = night[lessonIndex];
          results1.push(typeof cb === "function" ? cb(lesson, nightIndex, lessonIndex) : void 0);
        }
        return results1;
      })());
    }
    return results;
  };

  Schedule.prototype.getInstructors = function(nightIndex, lessonIndex, sanitize) {
    var instructors, night;
    if (sanitize == null) {
      sanitize = true;
    }
    night = this.nights[nightIndex];
    if (lessonIndex > night.length - 1) {
      instructors = night[0];
    } else {
      instructors = night[lessonIndex];
    }
    if (sanitize) {
      return this.sanitizeInstructors(instructors);
    } else {
      return instructors;
    }
  };

  Schedule.prototype.lessonCount = function() {
    var count;
    count = 0;
    this.forEachLesson(function() {
      return count++;
    });
    return count;
  };

  Schedule.prototype.instructorCounts = function() {
    var counts;
    counts = {};
    this.forEachLesson((function(_this) {
      return function(instructors) {
        var ifNecessary, instructor, k, len, results;
        results = [];
        for (k = 0, len = instructors.length; k < len; k++) {
          instructor = instructors[k];
          ifNecessary = instructor[instructor.length - 1] === '?';
          instructor = _this.sanitizeInstructor(instructor);
          if (counts[instructor] == null) {
            counts[instructor] = 0;
          }
          results.push(counts[instructor] += ifNecessary ? 0.5 : 1);
        }
        return results;
      };
    })(this));
    return counts;
  };

  Schedule.prototype.createRandomSchedule = function(classesPerNight, maxInstructors) {
    var availableInstructors, i, night, nights, numInstructors;
    if (classesPerNight == null) {
      classesPerNight = 2;
    }
    if (maxInstructors == null) {
      maxInstructors = 2;
    }
    nights = (function() {
      var k, len, ref, results;
      ref = this.nights;
      results = [];
      for (k = 0, len = ref.length; k < len; k++) {
        night = ref[k];
        results.push((function() {
          var l, ref1, results1;
          results1 = [];
          for (i = l = 0, ref1 = classesPerNight - 1; 0 <= ref1 ? l <= ref1 : l >= ref1; i = 0 <= ref1 ? ++l : --l) {
            if (night.length === 1) {
              availableInstructors = night[0];
            } else {
              availableInstructors = night[i];
            }
            numInstructors = 1 + Math.floor(Math.random() * (maxInstructors - 1));
            results1.push((function() {
              var m, ref2, results2;
              results2 = [];
              for (i = m = 0, ref2 = numInstructors - 1; 0 <= ref2 ? m <= ref2 : m >= ref2; i = 0 <= ref2 ? ++m : --m) {
                results2.push(availableInstructors[Math.floor(Math.random() * availableInstructors.length)]);
              }
              return results2;
            })());
          }
          return results1;
        })());
      }
      return results;
    }).call(this);
    return new Schedule(nights, true);
  };

  Schedule.prototype.toString = function() {
    var nights;
    nights = this.nights.map(function(lessons, i) {
      lessons = lessons.map(function(instructors, j) {
        return "  " + j + ": " + (instructors.join(' and '));
      });
      lessons.unshift("Night " + i);
      return lessons.join('\n');
    });
    return nights.join('\n');
  };

  return Schedule;

})();


