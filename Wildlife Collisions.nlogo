breed [ animals animal ]

;; Link indicating the adult a juvenile should follow during their life.
directed-link-breed [ parents parent ]

globals [
  SPLIT-XCOR                ;; the abscissa of the location of the split between the halves
  TICKS-PER-DAY             ;; number of ticks in a day; assumed to be even
  DAYS-PER-MONTH            ;; number of days in a month
  MONTHS-PER-YEAR           ;; number of months in a year
  TICKS-PER-MONTH           ;; derived; number of ticks in a month
  TICKS-PER-YEAR            ;; derived; number of ticks in a year
  YEARLY-SURVIVAL-RATE      ;; survival rate per year for animals before reaching age 4
  DAILY-OLD-SURVIVAL-RATE   ;; survival rate per day for animals at reaching age 4
  TICKLY-SURVIVAL-RATE      ;; derived; survival rate per tick for animals before reaching age 4
  TICKLY-OLD-SURVIVAL-RATE  ;; derived; survival rate per tick for animals at reaching age 4
  ANIMAL-SPEED              ;; number of patches traveled per tick by animals
  ANIMAL-ANGLE              ;; number indicating the view width upon walking of the animals
  TICK-OFFSET               ;; offset of ticks starting at the simulation
  MAX-TICKS-JUVENILE        ;; maximum number of ticks after birth a animal can be a juvenile
  MAX-TICKS-SUB-ADULT       ;; maximum number of ticks after birth a animal can be a sub-adult
  n-hits                    ;; number of animals hit by a car and afterwards died
  n-road-crossings          ;; number of times the road is crossed, including attempts
  n-passages-used           ;; number of times the passage is used to cross the road
  n-fences-bumped           ;; number of times an animal bumps into a fence blocking the road
  road-effective?           ;; boolean indicating whether the road can causes hits
  fences                    ;; list of ordinate points locating the fences
  passages                  ;; list of ordinate points locating the passages
  mating-season?            ;; boolean indicating whether in the current update it is mating season
  time                      ;; fraction of the day within go
  day                       ;; number of day in month within go
  month                     ;; number of month in year within go
  year                      ;; number of year within go
]

animals-own [
  sex                       ;; 1 is male and 0 is female
  pregnant?                 ;; boolean indicating whether the animal is pregnant
  age                       ;; number of ticks the animal is supposed to have lived
  has-territory?            ;; boolean indicating whether the animal has claimed a territory
  territory-x               ;; number indicating the abscissa of the position of the territory, if any
  territory-y               ;; number indicating the ordinate of the position of the territory, if any
]

to setup
  clear-all

  ;; Set the default constants for the simulation.
  set TICKS-PER-DAY 20
  set DAYS-PER-MONTH 30
  set MONTHS-PER-YEAR 12
  set YEARLY-SURVIVAL-RATE 0.74
  set DAILY-OLD-SURVIVAL-RATE 0.5
  set ANIMAL-SPEED 0.1
  set ANIMAL-ANGLE 60
  set n-hits 0
  set n-road-crossings 0
  set n-passages-used 0
  set n-fences-bumped 0
  set road-effective? false

  ;; Compute the derived constant values, which are assumed to be set now.
  set TICKS-PER-MONTH TICKS-PER-DAY * DAYS-PER-MONTH
  set TICKS-PER-YEAR TICKS-PER-MONTH * MONTHS-PER-YEAR
  set TICKLY-SURVIVAL-RATE YEARLY-SURVIVAL-RATE ^ (1 / TICKS-PER-YEAR)
  set TICKLY-OLD-SURVIVAL-RATE DAILY-OLD-SURVIVAL-RATE ^ (1 / TICKS-PER-DAY)

  ;; Compute the constants depending on the derived constants now.
  set MAX-TICKS-JUVENILE 2 * TICKS-PER-MONTH
  set MAX-TICKS-SUB-ADULT MAX-TICKS-JUVENILE + 4 * TICKS-PER-MONTH
  set TICK-OFFSET 2 * TICKS-PER-MONTH   ;; We start in 0001-03-01.

  ;; The world is divided into to equal halves, one with xcor > 0.5 and one with xcor < 0.5.
  ;; The road is then assumed to split the halves, with xcor = 0.5.
  resize-world -9 10 0 23
  set SPLIT-XCOR 0.5
  ask patches [ set pcolor white ]

  set-default-shape animals "dot"

  ;; Calculate positions for the fences and passages.
  ;; The fences are lines along the full border of random patches.
  ;; The passages are points along random patches, with most passages placed
  ;; along fences and the other spread further randomly.
  set fences n-of n-fences (range min-pycor (max-pycor + 1))
  let passages-patches up-to-n-of n-passages fences
  if n-passages > n-fences [
    set passages-patches sentence passages-patches up-to-n-of (n-passages - n-fences) (range min-pycor max-pycor)
  ]
  set passages map [ y -> y + random-float 1 ] passages-patches

  ask patches [
    sprout-animals 1 [
      set sex random 2
      set age random (5 * TICKS-PER-YEAR - MAX-TICKS-SUB-ADUlT) + MAX-TICKS-SUB-ADULT
      set pregnant? sex = 0
      set color ifelse-value sex = 0 [ pink ] [ blue ]
      set has-territory? true
      set territory-x pxcor
      set territory-y pycor
    ]
  ]

  reset-ticks
end

;; Reports the fraction of the day passed on ticks relative to the start offset.
to-report time?
  report (TICK-OFFSET + ticks) mod TICKS-PER-DAY
end

;; Reports the number of the day on ticks relative to the start offset.
to-report day?
  report floor ((TICK-OFFSET + ticks) / TICKS-PER-DAY) mod DAYS-PER-MONTH + 1
end

;; Reports the number of the month on ticks relative to the start offset.
to-report month?
  report floor ((TICK-OFFSET + ticks) / TICKS-PER-MONTH) mod MONTHS-PER-YEAR + 1
end

;; Reports the number of the year on ticks relative to the start offset.
;; The first year is postulated as having the number 1.
to-report year?
  report floor ((TICK-OFFSET + ticks) / TICKS-PER-YEAR) + 1
end

to go
  if ticks >= duration * TICKS-PER-YEAR [ stop ]

  if ticks = establishment * TICKS-PER-YEAR [
    draw-split
    set road-effective? true
  ]

  set time time?
  set day day?
  set month month?
  set year year?
  set mating-season? month = 7 or month = 8

  check-stage-transition
  move-animals
  check-alive
  if month = 3 and day = 2 [ give-birth ]

  tick
end

;; Let a animal die with their childs when they are still connected.
to animal-die ;; animal procedure
  ask in-parent-neighbors [ die ]
  die
end

;; Apply the actions corresponding to a transition of a stage of life, like
;; transforming from juvenile into sub-adult and sub-adult in adult.
to check-stage-transition
  ask animals with [ age = MAX-TICKS-JUVENILE + 1 ] [
    set color red
    ask my-out-parents [ die ]
  ]

  ask animals with [ age = MAX-TICKS-SUB-ADULT + 1 ] [
    if not has-territory? [ animal-die ]

    set color ifelse-value sex = 0 [ pink ] [ blue ]
  ]
end

;; Check for each animal whether they have reached their final age expressed in
;; number of ticks. If so, the animals dies, while otherwise, the age is
;; increased with a single tick.
to check-alive
  ask animals [
    let survival-rate
      ifelse-value age < 4 * TICKS-PER-YEAR [ TICKLY-SURVIVAL-RATE ] [ TICKLY-OLD-SURVIVAL-RATE]
    if random-float 1 > survival-rate [
      animal-die
    ]
    set age age + 1
  ]
end

;; Let all pregnant animals give birth to three juveniles, which are linked to
;; the mother. The juveniles start with the pink color regardless of their sex,
;; as they always keep walking with their mother as juvenile.
to give-birth
  ask animals with [ pregnant? ] [
    set pregnant? false
    set color pink

    hatch-animals 3 [
      create-parent-to myself
      set sex random 2
      set age 0
      set heading random-float 360
      set has-territory? false
    ]
  ]
end

;; Let a male animal walk around his territory in the first half of the day,
;; looking for female animals to mate with. At the other half of the day, the
;; male walks back to his territory.
to search-a-mater ;; animal procedure
  let back-to-home? time >= TICKS-PER-DAY / 2

  ifelse back-to-home? [
    ifelse (territory-x - xcor) ^ 2 + (territory-y - ycor) ^ 2 < ANIMAL-SPEED ^ 2 [
      set xcor territory-x
      set ycor territory-y
    ] [
      set heading atan (territory-x - xcor) (territory-y - ycor)
      fd ANIMAL-SPEED
    ]
  ] [
    face one-of [neighbors] of patch territory-x territory-y
    fd ANIMAL-SPEED

    let px pxcor
    let py pycor
    ask animals with [ territory-x = pxcor and territory-y = pycor and has-territory? and
               territory-x = px and territory-y = py and sex = 0 ] [
      set color green
      set pregnant? true
    ]
  ]
end

;; Make the movement for adult animals, e.g. keep standing except for males
;; during the mating season, during which they search for a mater.
to move-adult ;; animal procedure
  if mating-season? and sex = 1 [ search-a-mater ]
end

;; Make the movement for sub-adult animals, e.g. looking for a territory before
;; they become adults by a random walk.
to move-sub-adult ;; animal procedure
  if has-territory? [ stop ]

  ;; Walk in the direction within a viewpoint of ANIMAL-ANGLE degrees.
  set heading heading - ANIMAL-ANGLE / 2 + random-float ANIMAL-ANGLE
  fd ANIMAL-SPEED

  ;; Check whether the sub-adult can colonize the current patch.
  let px pxcor
  let py pycor
  if count (animals-on patch px py)
     with [ territory-x = px and territory-y = py and has-territory? ] = 0 [
    set has-territory? true
    set territory-x pxcor
    set territory-y pycor
  ]
end

;; Make the movement rules for juvenile animals, e.g. following their mother.
to move-juvenile  ;; animal procedure
  let x 0
  let y 0

  ask out-parent-neighbors [
    set x xcor
    set y ycor
  ]

  set xcor x
  set ycor y
end

;; Make all animals walking a further step according to their rules.
;; If the road is effective, they cannot walk through fences while passages are
;; safe spots to cross the road to avoid being hit with some probablity.
to move-animals
  ;; The juveniles follow their mother, so we will let them move later.
  ask animals with [ age > MAX-TICKS-JUVENILE ] [
    ;; Check whether there is a passage nearby, with 'nearby' defined as the
    ;; passage being in a 0.1 × 0.1 grid around the animal.
    let passage-nearby? false
    if abs xcor < 0.1 [
      let nearby-passage filter [ y -> abs (y - ycor) < 0.1 ] passages
      if length nearby-passage > 0 [ set passage-nearby? true ]
    ]

    ;; Check whether there is a fence nearby
    let fence-nearby? member? pycor fences

    let was-on-right? xcor >= SPLIT-XCOR
    ifelse age > MAX-TICKS-SUB-ADULT [ move-adult ] [ move-sub-adult ]
    let is-on-left? xcor <= SPLIT-XCOR

    ;; If an effective road is crossed, this crossing is assumed to be safe
    ;; if a passage is nearby, while otherwise, the crossing succeeds only
    ;; with some probability, depending on whether cars hit the animal.
    if was-on-right? = is-on-left? and road-effective? [
      ifelse passage-nearby? [
        set n-passages-used n-passages-used + 1
      ] [
        ifelse fence-nearby? [
          bk ANIMAL-SPEED
          set heading heading + 180
          set n-fences-bumped n-fences-bumped + 1
        ] [
          ifelse random-float 1 <= MORTALITY [
            set n-hits n-hits + 1
            animal-die
          ] [
            set n-road-crossings n-road-crossings + 1
          ]
        ]
      ]
    ]
  ]

  ask animals with [ age <= MAX-TICKS-JUVENILE ] [
    move-juvenile
  ]
end

;; Make visual markers on the field for the road, fences and passages.
to draw-split
  crt 1 [
    setxy SPLIT-XCOR min-pycor
    set color black
    pd
    set pen-size 5
    set heading 0
    fd world-height
    die
  ]

  foreach fences [ i ->
    crt 1 [
      setxy SPLIT-XCOR i
      set color grey
      pd
      set pen-size 8
      set heading 0
      fd 1
      die
    ]
  ]

  foreach passages [ i ->
    crt 1 [
      setxy SPLIT-XCOR i
      set color orange
      pd
      set pen-size 10
      set heading 0
      fd ANIMAL-SPEED
      die
    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
192
10
460
331
-1
-1
13.0
1
10
1
1
1
0
1
1
1
-9
10
0
23
1
1
1
ticks
30.0

BUTTON
10
10
83
43
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
88
10
151
43
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
10
53
182
86
duration
duration
0
50
35.0
1
1
year
HORIZONTAL

SLIDER
10
91
182
124
establishment
establishment
0
duration
10.0
1
1
year
HORIZONTAL

SLIDER
10
129
182
162
mortality
mortality
0
1
0.5
0.01
1
NIL
HORIZONTAL

SLIDER
10
167
182
200
n-fences
n-fences
0
24
6.0
6
1
NIL
HORIZONTAL

SLIDER
10
205
182
238
n-passages
n-passages
0
24
6.0
6
1
NIL
HORIZONTAL

PLOT
470
265
670
415
Animals over time
Time
Count
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count animals"

MONITOR
470
10
609
55
Number of animals
count animals
0
1
11

MONITOR
470
60
617
105
Number of road hits
n-hits
0
1
11

MONITOR
470
110
699
155
Number of times passages used
n-passages-used
0
1
11

MONITOR
470
160
732
205
Number of successful road crossings
n-road-crossings
0
1
11

MONITOR
614
10
739
55
Mean animal age
mean [age] of animals / (TICKS-PER-DAY * DAYS-PER-MONTH * MONTHS-PER-YEAR)
2
1
11

MONITOR
235
336
292
381
Day
day?
0
1
11

MONITOR
297
336
354
381
Month
month?
0
1
11

MONITOR
359
336
416
381
Year
year?
0
1
11

MONITOR
470
210
688
255
Number times bumped into fence
n-fences-bumped
1
1
11

@#$#@#$#@
## WHAT IS IT?

This model tries to simulate a population living in a natural habitat with a road passing through. The main goal is to find the benefits of using fences and/or passages to reduce deaths.

## HOW IT WORKS

Animals have an age and a sex: male or female. Both these parameters define the movement of the animals. The age defines a stage of life by looking at the range of numeric age:
- Juvenile (2 months): stays with his/her mom.
- Sub-adult (4 months): searches territory (if not found before the max age of a sub-adult, he/she dies)
- Adult: stays at his/her territory; male search for females during mating season (July and August) in his neighborhood to make pregnant (after which she will give birth to three juveniles at 2 March)

There are fences and passages blocking the road:
- Fences: an animal that encounters the fence just makes a u-turn and walks in the opposite direction of the road
- Passage: an animal can cross the road safely through a passage
When animals cross the road they die with a certain probability: the mortality.

## HOW TO USE IT

Sliders:
- duration: Amount of years the simulation will run for: 20+ years would be a logical choice
- establishment: When the road will be established
- mortality: The probabilty an animal dies when trying to cross the road, 10 years would be a logical choice
- n-fences: Amount of fences placed around the road (maximum of 24)
- n-passages: Amount of passages that animals can use to cross the road (maximum of 24)

Counters:
- number of animals: amount of living animals
- mean animal age: mean age of all living animals
- number of road hits: the amount of animals that died because of a road hit
- number of times passages used: amount of times an animal has crossed the road by using a passage
- number of succesful road crossings: amount of times an animal has succesfully
- number times bumped into fence: amount of times an animal bumped into a fence when trying to cross the road
- day: starts at 1, 30 days in a month
- month: starts at 3, 12 months in a year
- year: starts at 1

Graph:
- Animals over time: shows the amount of animals alive over the time

## THINGS TO NOTICE

Animals are shown as dots: sub-adults will be red, male adults blue, female adults pink and pregnant female adults green.
Note that juveniles will not be shown because they are always stuck with their mother.

It can occur that the simulation will run rather slowly when using a high speed. Just disable 'view updates'.

## THINGS TO TRY

It's best to fix the duration and the establishment. It's interesting to play with the mortality rate. However, for the purpose of this simulation, it's most interesting to play with the number of fences and number of passages.

## EXTENDING THE MODEL

An extension of the model could be adding multiple roads and look if the behavior of the fields between the roads is equally distributed for example.

## RELATED MODELS

Road Effects on Population Persistence, available on: https://sites.google.com/site/roadmitigation/.

## CREDITS AND REFERENCES

The simulation rules has been based on the rules presented in the article 'Wildlife–vehicle collision mitigation: Is partial fencing the answer? An agent-based model approach' by Fernando Ascensão, Anthony Clevenger, Margarida Santos-Reis, Paulo Urbano and Nathan Jackson, published in Ecological Modelling, Volume 257 (2013) with ISSN 0304-3800 on pages 36-43, available on https://doi.org/10.1016/j.ecolmodel.2013.02.026.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

dot
false
0
Circle -7500403 true true 90 90 120
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
