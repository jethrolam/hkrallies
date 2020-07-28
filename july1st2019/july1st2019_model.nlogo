extensions [ gis ]                                    ; activate GIS extension

breed [protesters protester]                          ;the sheeps
;breed [cops cop]                                     ;the dogs
;breed [zombies zombie]                               ; the walking dead

globals [ gis-envelope                                ; declare global variables
  dist-raster
  VP
  PopArea
  EntryExit
  EntryExit2
  max-capacity-per-patch
  count-finished
  count-die
  count-leave
  count-late
  ticks-first-finished
  ticks-10-finished
  ticks-20-finished
  ticks-last-finished
  avgSpeed
  avgCapacity
  avgPatience
  count-protesters
  blnEarlyStop
  blnStop
  nMax
  min-dist
  max-dist
  percent-done
  percent-time
  oldPercent
  PatienceDie
  PatienceRandom
  in
  m
  obsRallyTime
  dblError
  count-leave-CWB
  count-leave-WC
  count-leave-Admiralty
  count-entry-VP
  count-entry-Others
  count-entry-CWB
  count-entry-WC
]

patches-own [         ; declare local variables of patch objects
  dist                ; how far it is from the destination in meters
  capacity            ; how many turtle here
  speed               ; how fast the turtle can move forward based on density of surrounding 8 neighbors
  name
  gate                ; a 1/0 binary attribute to indicate whether it is an exit gateway or not
]

turtles-own [         ; declare local variables of turtle objects
  wall-turn-check     ; Holds the random variable for the wall sub-routine.
  can-fd?             ; whether the turtle can move forward based on street geometry, capacity of patch-ahead
  patience            ; how much patience the turtle has before random walk
]

to setup
  clear-all
  ; Loads the spatial datasets
  set dist-raster gis:load-dataset "GIS/distType05222020.asc"
  ;set dist-raster gis:load-dataset "GIS/disttypeall_final.asc"           ; updated distance grid with wider Arsenal St
  ;set EntryExit gis:load-dataset "GIS/ExitEntry_2018_new.shp"                   ; updated ExitEntry layer with separate & smaller Southern and Canal Bridge entrances/exits
  set EntryExit gis:load-dataset "GIS/ExitEntry2019.shp"                ; old ExitEntry layer with combined Southern and Canal Bridge extrances/exits
  set PopArea gis:load-dataset "GIS/RallyArea2019.shp"

  ; set the map extent
  set gis-envelope gis:envelope-union-of (gis:envelope-of EntryExit) (gis:envelope-of dist-raster)
  ; set the projected coordinate system
  gis:set-transformation gis-envelope (list min-pxcor max-pxcor min-pycor max-pycor)
  gis:set-world-envelope gis-envelope
  resize-world 0 gis:width-of dist-raster 0 gis:height-of dist-raster

  print gis-envelope
  print (list min-pxcor max-pxcor min-pycor max-pycor)

  ; set global variables
  set max-capacity-per-patch max-capacity * raster-size * raster-size
  ;set second-per-tick 3
  set count-finished 0
  set count-die 0
  set count-leave 0
  set count-late 0

  set count-leave-CWB 0
  set count-leave-WC 0
  set count-leave-Admiralty 0
  set count-entry-VP 0
  set count-entry-Others 0
  set count-entry-CWB 0
  set count-entry-WC 0

  set nMax 0
  set blnStop false
  set blnEarlyStop false
  set PatienceDie 100
  set PatienceRandom 20
  set avgPatience 1
  set obsRallyTime (8 * 3600 / seconds-per-tick)
  set dblError 100

  set in 10
  set m 1

  ; clear everything but global variables
  clear-turtles
  clear-patches
  clear-drawing
  clear-all-plots
  clear-ticks

  gis:apply-raster dist-raster dist                       ; set the distance raster to patch variable
;;  people got trapped here @ 1341 125 & 1304 140 during vector to raster conversion (or ASCII conversion?), need to fill in
  ;ask patch 1366 159 [ set dist 2976 ]             ; the corner of Great George St to East Point St



  ask patch 1381 143 [ set pcolor 17.08534061950798]             ; the intersection of main route and East Point St

  ask patch 1659 204 [ set dist 4094.806]             ; Causeway Rd W-bound
  ask patch 1658 204 [ set dist 4092.806]             ; Causeway Rd W-bound
  ask patch 1655 201 [ set dist 4082.321]             ; Causeway Rd W-bound
  ask patch 1654 200 [ set dist 4079.493]             ; Causeway Rd W-bound

  ask patch 1357 141 [ set dist 3279.288]             ; SOGO
  ask patch 1358 141 [ set dist 3281.288]             ; SOGO
  ask patch 1359 141 [ set dist 3283.288]             ; SOGO
  ask patch 1358 140 [ set dist 3284.116]             ; SOGO
  ask patch 1359 140 [ set dist 3286.116]             ; SOGO
  ask patch 1360 140 [ set dist 3288.116]             ; SOGO
  ask patch 1359 139 [ set dist 3284.944]             ; SOGO
  ask patch 1360 139 [ set dist 3286.944]             ; SOGO
  ask patch 1361 139 [ set dist 3288.944]             ; SOGO
  ask patch 1360 138 [ set dist 3289.773]             ; SOGO
  ask patch 1361 138 [ set dist 3291.773]             ; SOGO
  ask patch 1362 138 [ set dist 3293.773]             ; SOGO

  ask patch 1222 117 [ set dist 2978.92]             ; the canal bridge
  ask patch 1217 115 [ set dist 2967.263]             ; the canal bridge
  ask patch 1212 113 [ set dist 2955.606]             ; the canal bridge

  ask patch 1207 104 [ set dist 2936.979]             ; the canal bridge
  ask patch 1203 103 [ set dist 2926.494]             ; the canal bridge
  ask patch 1207 103 [ set dist 2936.15]             ; the canal bridge
  ask patch 1208 103 [ set dist 2938.15]             ; the canal bridge
  ask patch 1201 102 [ set dist 2921.665]             ; the canal bridge
  ask patch 1205 102 [ set dist 2931.322]             ; the canal bridge
  ask patch 1206 102 [ set dist 2933.322]             ; the canal bridge
  ask patch 1207 102 [ set dist 2935.322]             ; the canal bridge
  ask patch 1208 102 [ set dist 2937.322]             ; the canal bridge
  ask patch 1209 102 [ set dist 2939.322]             ; the canal bridge
  ask patch 1202 101 [ set dist 2926.494]             ; the canal bridge
  ask patch 1203 101 [ set dist 2928.494]             ; the canal bridge
  ask patch 1204 101 [ set dist 2930.494]             ; the canal bridge
  ask patch 1205 101 [ set dist 2932.494]             ; the canal bridge
  ask patch 1206 101 [ set dist 2934.494]             ; the canal bridge
  ask patch 1202 100 [ set dist 2928.494]             ; the canal bridge
  ask patch 1203 100 [ set dist 2930.494]             ; the canal bridge



  ask patch 1022 44 [ set dist 2501.96]             ; Before southern
  ask patch 994 36 [ set dist 2437.332]             ; Before southern
  ask patch 985 34 [ set dist 2417.675]             ; Before southern
  ask patch 981 33 [ set dist 2406.847]             ; Before southern

  ask patch 787 0 [ set dist 1998.563]             ; Southern
  ask patch 788 0 [ set dist 2000.563]             ; Southern
  ask patch 787 1 [ set dist 1997.734]             ; Southern
  ask patch 788 1 [ set dist 1999.734]             ; Southern
  ask patch 787 2 [ set dist 1996.906]             ; Southern
  ask patch 788 2 [ set dist 1998.906]             ; Southern
  ask patch 787 3 [ set dist 1996.077]             ; Southern
  ask patch 788 3 [ set dist 1998.077]             ; Southern

  ask patch 736 6 [ set dist 1887.592]             ; After southern
  ask patch 721 7 [ set dist 1851.935]             ; After southern
  ask patch 720 8 [ set dist 1851.935]             ; After southern
  ask patch 698 10 [ set dist 1806.278 ]             ; After southern
  ask patch 697 10 [ set dist 1804.278 ]             ; After southern
  ask patch 696 10 [ set dist 1802.278 ]             ; After southern
  ask patch 695 10 [ set dist 1800.278 ]             ; After southern
  ask patch 686 11 [ set dist 1779.45 ]             ; After southern
  ask patch 685 11 [ set dist 1777.45 ]             ; After southern
  ask patch 684 11 [ set dist 1775.45 ]             ; After southern
  ask patch 683 11 [ set dist 1773.45 ]             ; After southern
  ask patch 673 12 [ set dist 1752.621 ]             ; After southern
  ask patch 672 12 [ set dist 1750.621 ]             ; After southern

  ask patch 573 49 [ set dist 1122.318]             ; the turn from Lockhart road turn to Arsenal St
  ask patch 452 27 [ set dist 1281.367]             ; United Center
  ask patch 443 28 [ set dist 1262.538]             ; United Center
  ask patch 442 28 [ set dist 1260.538]             ; United Center
  ask patch 438 36 [ set dist 817.0925]             ; United Center
  ask patch 435 29 [ set dist 1243.71]             ; United Center
  ask patch 433 37 [ set dist 809.2935]             ; United Center
  ask patch 432 30 [ set dist 1236.881]             ; United Center
  ask patch 431 37 [ set dist 809.2935]             ; United Center
  ask patch 430 31 [ set dist 1232.053]             ; United Center
  ask patch 426 38 [ set dist 807.2935]             ; United Center
  ask patch 425 38 [ set dist 805.2935]             ; United Center

;  ask patch 1172 140 [ set dist 2980.412 ]
;;  ask patch 1368 114 [ set dist 3511.181 ]
;;  ask patch 1359 118 [ set dist 3486.696 ]
;;  ask patch 1322 132 [ set dist 3389.442 ]
;;  ask patch 1304 140 [ set dist 3339.158 ]
;;  ask patch 1300 140 [ set dist 3327.501 ]

  ; draw the distance raster by stretching the min and max distance
  set min-dist gis:minimum-of dist-raster
  set max-dist gis:maximum-of dist-raster
  ask patches
  [ ; note the use of the "<= 0 or >= 0" technique to filter out "not a number" values, as discussed in the documentation.
    ifelse (dist <= 0) or (dist >= 0) [
      set pcolor scale-color red dist min-dist (max-dist)
      set capacity 0                               ; the capacity on the rally route will be 0, off-route would be -1
      set speed max-speed
    ]
    [
      set pcolor black
      set capacity -1
    ]
  ]

  ; draw vector layers
  gis:set-drawing-color yellow
  ;set EntryExit2 gis:find-less-than EntryExit "ID" 1            ; dor yu
  ;gis:draw EntryExit2 1
  gis:draw EntryExit 1
  set VP gis:find-greater-than EntryExit "Start" 0
  ask patches gis:intersecting VP                  ; fill the Victoria Park
    [
      set pcolor cyan
      ;set name "VP"
    ]

  ; fill the name of Rally Area into the patches
  foreach gis:feature-list-of PopArea
   [ x ->
      ask patches gis:intersecting x
     [ set name gis:property-value x "Name" ]
  ]

   ;Exclude the Causeway Rd
  ask patches with [name = "Causeway Rd E-bound"] [
    set pcolor black
    ;set dist max-dist
  ]

  if not Tributaries-open? [
    ; use PopArea as exclusionary layer to color patches black if
    ;let ExcludedRoutes gis:find-less-than PopArea "Exclude" 0               ; Find -1
    let ExcludedRoutes gis:find-greater-than PopArea "Exclude" 1               ; Find 2
    ;let ExcludedRoutes gis:find-range PopArea "Exclude" 0 2
    ask patches gis:intersecting ExcludedRoutes [                ; black out conflict areas
      set pcolor black
      ;set dist max-dist                                        ; set them to the highest distance to avoid downhill2 algorithm from going there
    ]
;    ]
  ]

  ; those late protesters at location besides VP
  if Other-entrance? [
    let VP_Other gis:find-greater-than EntryExit "VP_Other" 0                       ; use LateEntry for other entrances to route protesters besides VP
    gis:set-drawing-color green
    ask patches gis:intersecting VP_Other
      [
        set pcolor cyan
        set name "Other"
        ;set name gis:property gis:find-one-feature VP_Other "Name" location
      ]
  ]

  ; Account for early departure at ExtryExits gateways
  if Early-departure? [
    let polygons gis:find-greater-than EntryExit "Exit" 0                       ; use Exit field to allow protesters leave early at other exits
    gis:set-drawing-color green
    ask patches gis:intersecting polygons
      [
        set pcolor violet
        ;set name "Gates"
        set gate 1                             ; new line

      ]
  ]

  ; Account for late entry at ExtryExits gateways


  set-default-shape protesters "person"
  reset-ticks

end

to get-more-protesters [ fraction location ]
  ;ask patches with [ pcolor = cyan ] [
  ask n-of VP-Protesters patches with [ name = location ] [
    if (random-float 1 < fraction) [ sprout-protesters 1 [ set patience 1 ]]
    set capacity count turtles-here
    set speed max-speed
    if (location = "VP") [ set count-entry-VP count-entry-VP + 1]       ; monitor ppl starting from VP
  ]
end

to get-more-protesters-by-gateway [ n location ]
  let entryPolygon gis:find-one-feature EntryExit "Name" location
  if entryPolygon != nobody [
    let pplPatches patches gis:intersecting entryPolygon
    if n > count pplPatches [ set n count pplPatches ]
    ask n-of n pplPatches [
      sprout-protesters 1 [ set patience 1 ]
      set capacity count turtles-here
      set speed calc-speed capacity               ; use local update instead of global updates of update-capacity and update-speed
      ;set name "Gates"
      ;set plabel "Southern"
    ]
    set count-late count-late + n
    ; monitor people entry from CWB and WC
    if (location = "Central library") or (location = "Sogo") or (location = "Percival") or (location = "Canal bridge") [
      set count-entry-CWB count-entry-CWB + n
      ;print count-entry-CWB
    ]
    if (location = "Southern Pk") [ set count-entry-WC count-entry-WC + n ]
  ]
end

to new-protesters
  ; protesters arrive!!
  let protesters-needed (total-protesters - (count protesters + count-finished + count-leave))
  if protesters-needed > 0 [
  ;if total-protesters > (VP-Protesters + count-late) [
    let protesters-fraction (protesters-needed / count patches with [pcolor = cyan])         ; get the number of batches needed to have more protesters
    if ceiling protesters-fraction > 1 [ set protesters-fraction 1 ]                       ; if this is not the last batch, have protesters in all possible patches.
    if remainder ticks 100 = 0 and (ticks * seconds-per-tick / 60) < VP-EndTime-min [
      get-more-protesters protesters-fraction "VP"
      ; ***** Invite more protesters in other entrances

    ]                   ; generate more protesters every 100 ticks
    let protester-patch-ratio count protesters with [name = "VP"] / count patches with [name = "VP"]
    if ticks < 1 [ get-more-protesters protesters-fraction "VP"]
    ;if protester-patch-ratio <= 0.2 [ get-more-protesters protesters-fraction "VP"]
    if ticks > (time-late-Other * (60 / seconds-per-tick)) [
      set protester-patch-ratio count protesters with [name = "Other"] / count patches with [name = "Other"]
      ;if protester-patch-ratio <= 0.5 [ get-more-protesters protesters-fraction "Other"]
      if remainder ticks 100 = 0 [ get-more-protesters protesters-fraction "Other"]
    ]

    ; calculate how many people per ticks should be called based on ppl/min
    ; Given t = 3s, late-entry = 20 ppl/min = 1 ppl/t
    let n (entry-rate / (60 / seconds-per-tick))                 ; number of late entry at gateways per tick
    let CWB-WC-ratio 2      ; 2 to 1 ratio, i.e. if rate = 1000/min, CWB = n+n*((CWB-WC-ratio+1)/CWB-WC-ratio/4), WC = n-n*((CWB-WC-ratio+1)/CWB-WC-ratio)
    let CWB (n + n * (CWB-WC-ratio / (CWB-WC-ratio + 1) / 4))       ; to be split by 4 gateways in CWB
    let WC (n - n * (CWB-WC-ratio / (CWB-WC-ratio + 1)))
    if ticks > (time-late-CWB * (60 / seconds-per-tick)) [                   ; late crowd joined at Causeway Bay
      get-more-protesters-by-gateway CWB "Central library"                             ; Central library
      get-more-protesters-by-gateway CWB "Sogo"
      get-more-protesters-by-gateway CWB "Percival"
      get-more-protesters-by-gateway CWB "Canal bridge"
      ;set count-late count-late + (n * 4)
    ]
    if ticks > (time-late-WC * (60 / seconds-per-tick)) [                  ; late crowd joined at Wan Chai
      get-more-protesters-by-gateway WC "Southern Pk"
      ;set count-late count-late + n
    ]
  ]
  ;ask protesters [ set patience 1 ]                      ; this resets their patience at 1, but the patience level goes crazy without it. Need to subtract patience if they are walking

end

to go

  new-protesters
  ;if not any? protesters [

  let oldFinished count-finished

  ask protesters [
    ;let myDist gis:raster-sample dist-raster self                     ; get the distance variable of patch at the protester
    ;ifelse (dist <= 0) or (dist >= 0)                             ; head downhill if dist is a valid value (using pcolor = black would still include NaN patches for some reason)

    if dist = 0 [                                                   ; die and count finished if arrived destination
      set count-finished count-finished + 1
      if count-finished = 1 [
        set ticks-first-finished ticks
        ;show ticks
      ]
      die
    ]

;    if [pcolor] of patch-here = black [
;
;     ;set count-die count-die + 1
;     ;die
;      ifelse patience >= 20
;      ;set can-fd? true
;        [set count-die count-die + 1
;        die
;      ]
;        [set patience patience + 1
;        capacity-or-random
;      ]
;    ]

    ifelse ([dist] of patch-here <= 0) or ([dist] of patch-here >= 0)                             ; head downhill if dist is a valid value (using pcolor = black would still include NaN patches for some reason)

      [ rally ]
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;       ???????????????????????????????????????
      ; people in VP move towards the exit, but people in other entrances (i.e [name] of patch-here = "Other") do not move
      ; Use Patch Monitor under Tools to monitor the turtle movement, e.g. Sugar St - 1417 147; Great George St - 1403 180
      ; --> only the ones on the route would move, but not those on cyan colored patches with name = "Other"
      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

      ; if a protester steps outside
      [

        ifelse [pcolor] of patch-here = black [                                          ; there are some patches that have distance but it's colored black (e.g. Yee Wor St)
         ;set count-die count-die + 1

         ; GO SOMEWHERE to the nearest people who are moving?


          ifelse patience >= PatienceDie
          ;set can-fd? true
            [set count-die count-die + 1
            ;print (word who " is dying at " xcor ", " ycor " with patience level" patience)
            die
          ]
            [set patience patience + 1
            capacity-or-random
          ]

         ]
        [
         ; head towards the exit if it's in VP, random walk otherwise. If it's on route, then should go downhill based on distance
          if [name] of patch-here = "VP" [ exit 1590 255 ]
          if [name] of patch-here = "Other" [
            ;capacity-or-random
            exit (xcor - 1) ycor
            ;print (word who " is stuck at " xcor ", " ycor " with patience level" patience)
        ]
          if [name] of patch-here = "East Point Rd" [ exit (xcor - 1) ycor ]
          move-and-update
        ]

      ]

  ]
  ;if count-finished >= 100 [ stop ]

  if ticks > (Lockhart-YeeWor-StartTime-min * 60 / seconds-per-tick) and ticks < ((Lockhart-YeeWor-StartTime-min + Lockhart-YeeWor-Duration-min) * 60 / seconds-per-tick)  [
    ; open Lockhart Road and Yee Wor St
       ;ask patches with [name = "Yee Wor St W-bound"] [ set pcolor scale-color red dist min-dist max-dist ]
    ask patches with [name = "Yee Wor St W-bound"] [ set pcolor cyan ]
;    ask patch 1487 112 [ set pcolor cyan ]               ; don't know why repainting the patches would miss some patches and create a gap
;    ask patch 1487 111 [ set pcolor cyan ]
;    ask patch 1486 111 [ set pcolor cyan ]
;    ask patch 1485 111 [ set pcolor cyan ]
;    ask patch 1486 110 [ set pcolor cyan ]
;    ask patch 1485 110 [ set pcolor cyan ]
;    ask patch 1484 110 [ set pcolor cyan ]
;    ask patch 1483 110 [ set pcolor cyan ]
;    ask patch 1486 109 [ set pcolor cyan ]
;    ask patch 1485 109 [ set pcolor cyan ]
;    ask patch 1484 109 [ set pcolor cyan ]
;    ask patch 1483 109 [ set pcolor cyan ]
;    ask patch 1482 109 [ set pcolor cyan ]
;    ask patch 1485 108 [ set pcolor cyan ]
;    ask patch 1484 108 [ set pcolor cyan ]
;    ask patch 1483 108 [ set pcolor cyan ]
;    ask patch 1482 108 [ set pcolor cyan ]
;    ask patch 1481 108 [ set pcolor cyan ]
;    ask patch 1480 108 [ set pcolor cyan ]
;    ask patch 1485 107 [ set pcolor cyan ]
;    ask patch 1484 107 [ set pcolor cyan ]
;    ask patch 1483 107 [ set pcolor cyan ]
;    ask patch 1480 107 [ set pcolor cyan ]
;    ask patch 1479 107 [ set pcolor cyan ]
;    ask patch 1478 107 [ set pcolor cyan ]
;    ask patch 1484 106 [ set pcolor cyan ]
;    ask patch 1483 106 [ set pcolor cyan ]
;    ask patch 1482 106 [ set pcolor cyan ]
;    ask patch 1481 106 [ set pcolor cyan ]
;    ask patch 1480 106 [ set pcolor cyan ]
;    ask patch 1479 106 [ set pcolor cyan ]
;    ask patch 1478 106 [ set pcolor cyan ]
;    ask patch 1484 105 [ set pcolor cyan ]
;    ask patch 1483 105 [ set pcolor cyan ]

    ask patch 1502 108 [ set pcolor cyan ]               ; don't know why repainting the patches would miss some patches and create a gap
    ask patch 1503 108 [ set pcolor cyan ]
    ask patch 1502 107 [ set pcolor cyan ]
    ask patch 1503 107 [ set pcolor cyan ]
    ask patch 1502 106 [ set pcolor cyan ]
    ask patch 1502 105 [ set pcolor cyan ]
    ask patch 1501 105 [ set pcolor cyan ]
    ask patch 1501 104 [ set pcolor cyan ]
    ask patch 1500 104 [ set pcolor cyan ]
    ask patch 1500 103 [ set pcolor cyan ]
    ask patch 1499 103 [ set pcolor cyan ]
    ask patch 1499 102 [ set pcolor cyan ]
    ask patch 1499 101 [ set pcolor cyan ]
    ask patch 1498 101 [ set pcolor cyan ]
    ask patch 1497 101 [ set pcolor cyan ]
    ask patch 1496 101 [ set pcolor cyan ]
    ask patch 1495 101 [ set pcolor cyan ]
    ask patch 1495 102 [ set pcolor cyan ]
    ask patch 1494 102 [ set pcolor cyan ]
    ;ask patch 1486 111 [ set pcolor cyan ]
    ;ask patches with [name = "East Point Rd"] [ set pcolor scale-color red dist min-dist max-dist ]
    ask patches with [name = "Causeway Rd E-bound"] [ set pcolor cyan ]
    ask patches with [name = "East Point Rd"] [ set pcolor cyan ]
  ]

  set percent-done precision ((count-finished + count-leave) / total-protesters * 100) 2
  set percent-time precision ((ticks * seconds-per-tick / 60 / Simulation-time-min) * 100) 2
  let earlyStopThres1 3
  let earlyStopThres2 2

  ;let blnCheck false
  let maxTime 1

;  ; Can use percent-done or percent-time
;  if int percent-done != 0 [
;    ;print remainder int percent-done i
;    ;print i
;    if remainder int percent-done in = 0 [
;      ;set blnCheck true
;      set ticks-10-finished ticks
;      set ticks-last-finished ((ticks-10-finished) * (10 / m))
;      print (word in "% finished time: " ticks-10-finished)
;      print (word "Projected finished time: " ticks-last-finished)
;
;      if total-protesters > 500000 [ set maxTime 2 ]
;      if in > 10 and (ticks-last-finished * 3 / 60) > (Simulation-time-min * maxTime) [                      ; finish it early if it can't be done within +10% of time allowed
;        print "There is no hope to finish this mate~~"
;        stop
;      ]
;      set in (in + 10)
;      set m (m + 1)
;      print (word "in: " in " m: " m)
;
;    ]
;  ]

  if blnEarlyStop [
     print ticks
     stop
  ]
    ; Can use percent-done or percent-time
  if (percent-time >= 10) [
    ;print remainder int percent-done i
    ;print i
    ;if remainder int percent-done in = 0 [
    if remainder int percent-time in = 0 [
      ;set blnCheck true
      ;set ticks-10-finished ticks
      set ticks-10-finished percent-done
      ;set ticks-last-finished ((ticks-10-finished) * (10 / m))
      set ticks-last-finished (ticks * (100 / ticks-10-finished))
      set dblError (ticks-last-finished - obsRallyTime) / obsRallyTime * 100
      print (word in "%, " ticks-10-finished ", " ticks-last-finished)
      ;print (word "Projected finished time: " ticks-last-finished)

      if total-protesters > 500000 [ set maxTime 1.1 ]
      if in > 30 and (ticks-last-finished * 3 / 60) > (Simulation-time-min * maxTime) [                      ; finish it early if it can't be done within +10% of time allowed
          print "There is no hope to finish this mate~~"
          set blnEarlyStop true
          ;stop
      ]

;      if in > 60  [                      ; finish it early if it can't be done within +10% of time allowed
;        print "Stop for efficiency purposes ~~"
;        stop
;      ]

      set in (in + 10)
      ;set m (m + 1)
      ;print (word "in: " in " m: " m)

    ]
    if remainder int percent-done 95 = 0 and (percent-done >= 1) [
      set ticks-last-finished (ticks * (100 / 95))
      print (word percent-time "%, " percent-done ", " ticks-last-finished)
      set blnEarlyStop true
      ;stop
    ]
  ]

;  ifelse total-protesters >= 300000
;  [
;     ; Check the population % at 10% and 20% time, stop early if percent-time/percent-done > 3 times
;     if int percent-time != 0 [
;       if  remainder int percent-time 10 = 0 and blnEarlyStop = false [
;         if percent-time / percent-done > earlyStopThres1 [
;            ;show percent-time / percent-done
;            set oldPercent int percent-time
;            ;set blnEarlyStop true
;            ;print "First time"
;            show ticks
;         ]
;       ]
;     ]
;
;     ; Check it twice
;     if (int percent-time) >= (2 * oldPercent) and remainder int percent-time 10 = 0 [                        ; to avoid the same rounded percentile
;       if  remainder int percent-time 10 = 0 and blnEarlyStop = true [
;         ;print "Second time"
;         if percent-time / percent-done > earlyStopThres1 [
;           ;print "Protest is done early~~!"
;           stop
;         ]
;       ]
;     ]
;  ]
;  [
;     ; Check the time % at 10th percentile and 20th percentile of population, stop early if percent-time/percent-done > 1.5 times
;     if int percent-done != 0 [
;       if  remainder int percent-done 10 = 0 and blnEarlyStop = false [
;         if percent-time / percent-done > earlyStopThres2 [
;            ;show percent-time / percent-done
;            set oldPercent int percent-done
;            set blnEarlyStop true
;            print "First time"
;            show ticks
;         ]
;       ]
;     ]
;
;     ; Check it twice
;     if (int percent-done) >= (2 * oldPercent) and remainder int percent-done 10 = 0 [                        ; to avoid the same rounded percentile
;       if  remainder int percent-done 10 = 0 and blnEarlyStop = true [
;         ;print "Second time"
;         if percent-time / percent-done > earlyStopThres2 [
;           print "Protest is done early~~!"
;           stop
;         ]
;       ]
;     ]
;  ]




  if ticks > Simulation-time-min * 60 / seconds-per-tick [ stop ]                                   ; stop if it reaches the duration of simulation

  if total-protesters = (count protesters + count-finished + count-leave) and count-finished > 0 [
    ifelse oldFinished = count-finished
      [ set nMax nMax + 1 ]
      [ set nMax 0]
    if nMax = 50 [
      ;set blnStop true
      stop
      print "Protest is done~~!"
    ]

  ]

  update-capacity
  update-speed

  set avgSpeed mean [speed] of patches with [capacity > 0]
  set avgCapacity ((count protesters)/(count patches with [capacity > 0]))/(raster-size * raster-size)
  set avgPatience mean [patience] of protesters
  set count-protesters (count protesters)

  tick

end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  find the direction closer to the destination and then move forward 1 step
;  if two patches can have equal dist, then it will be more difficult as we will have to look at 2+ steps at the same time
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to rally
  set can-fd? false
  downhill2 [dist] of patch-here
  capacity-or-random

  ; override if the protester are diverted into the tributories
  ;if [name] of patch-here = "Yee Wor St W-bound" [ exit 1435 125 ]       ; 1423 126
  ;if [name] of patch-here = "East Point Rd" [ exit 1361 171 ]            ; 1358 177
;  if [name] of patch-here = "Override- Rodney St" [ exit 366 181 ]        ; 371 186

  ;if [name] of patch-here = "Queen's way Rd W-bound" [ exit 366 181 ]        ; 371 186
;  if [name] of patch-here = "SouthernW" [ if random 3 >= 1 [ exit 723 (10 + random -3)] ]
;  if [name] of patch-here = "Other" [
;    if not (([dist] of patch-here <= 0) or ([dist] of patch-here >= 0)) [
;      exit (xcor - 1) ycor
;      print (word who " is stuck at " xcor ", " ycor " with patience level" patience)
;    ]            ; some in "Others" entry gateway got trapped because dist = NaN
;  ]
  if [name] of patch-here = "Causeway Rd E-bound" [exit xcor (ycor - 1) ]
  ;if [name] of patch-here = "Causeway Rd W-bound" [exit (1503 + (random -1)) 101 ]
  if [name] of patch-here = "AfterSouthernE" [ if random 2 >= 1 [ exit 544 (28 + random -3)] ]     ; or y = 41
  if [name] of patch-here = "AfterSouthernW" [ if random 2 >= 1 [ exit 544 (21 + random -2)] ]
  ;if [name] of patch-here = "AfterArsenalE" [ if random 2 >= 1 [ exit 421 (41 + random -3)] ]
  if [name] of patch-here = "AfterArsenalE" [ if random 2 >= 1 [ capacity-walk ] ]
  if [name] of patch-here = "AfterArsenalW" [ if random 2 >= 1 [ exit 421 (36 + random -3)] ]
;  if [name] of patch-here = "Hennessy Rd E-bound" [ if random 3 >= 1 [ exit 491 (35 + (random -3))] ]
  if [name] of patch-here = "Arsenal St" [ if random 2 >= 1 [ exit (558 + (random 4)) 30] ]
  if [name] of patch-here = "Queen's Rd E - Rodney" [ if random 2 >= 1 [ exit 421 (41 + random -3)] ]     ; or y = 41
  if [name] of patch-here = "Queen's way Rd W-bound0" [ if random 2 >= 1 [ exit 369 (45 + random -1)] ]     ; or y = 41

  move-and-update

  ;if [name] of patch-here = "Gates" [ leave-early ]
  if [gate] of patch-here = 1 [ leave-early]                        ; replacement by gate attribute

end

to leave-early
  ; create a random number between 0 - 1, protester dies if the random number is < than random number
  ;if ((random-float 1) / patience) < leave-rate [
  let f 10                  ; default f (e.g. Admiralty)
  ifelse (xcor > 1100)        ; Get more people leave in WC than CWB
    [ set f 12 ]     ; in CWB
    [ if (xcor > 600) [ set f 2.5 ]     ; in WC
  ]
  if random-float 1 < (leave-rate / 100 / f) [     ; f is an empirical factor that considers the exit geometries to reflect the actual chance of exiting the rally
    set count-leave count-leave + 1
    ifelse xcor > 1100 [
      set count-leave-CWB (count-leave-CWB + 1)
    ]
    [
      ifelse xcor > 600
      [ set count-leave-WC (count-leave-WC + 1) ]
      [ set count-leave-Admiralty (count-leave-Admiralty + 1) ]
    ]
    die
  ]

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  move to this exit and assuming that this patch has a dist value <> NaN
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to exit [ x y ]
  facexy x y                       ; face the patch @ 1667 222 for flocking function                   ; 1370 115 is @ CWB intersection, 175 210 is @ exit
  set can-fd? true
  ;check-capacity-VP
  ;move-and-update
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  find the direction closer to the destination
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to downhill2 [current_dist]
  ;let pNeighbors neighbors with [ (dist >= 0) or (dist <= 0) ]       ; Pick only patches with a valid number (i.e. NOT NaN)
  ;let pNeighbors neighbors with [ pcolor != black ]       ; Pick only patches with a valid number (i.e. NOT NaN)
  move-to patch-here
  let i 0
  let can-exit? false
  while  [can-exit? = false] [
    ;let p min-one-of pNeighbors [dist]                            ; most efficient run, produce a single line of ants
    ;let p one-of neighbors with [ (dist >= 0) or (dist <= 0) ]          ; pick a neighbor with valid distance to destination, not NaN. For
    let p one-of neighbors with [ (dist >= 0) or (dist <= 0) ]          ; pick a neighbor with valid distance to destination, not NaN. For
    ;if p != nobody and pcolor != black [
    if p != nobody [
      if [pcolor] of p != black [
        if [dist] of p <= current_dist [
          face p
          set can-fd? true
        ]
      ]
    ]
    set i i + 1
    if (can-fd? = true) or (i = 4)  [ set can-exit? true ]
  ]
  ;set can-fd? false
  check-capacity
end

to capacity-or-random
  if can-fd? = false
    [
      ifelse patience >= PatienceRandom
      ;
       [ ifelse patience > PatienceDie [ die ] [ random-walk ]]
       [ if patience >= 2 [ capacity-walk ]]
    ]

end

to move-and-update
  ifelse can-fd? = true
    [
      fd (speed-step speed)                        ; already implemented in random walk and capacity walk already,
      if patience > 1 [ set patience patience - 1 ]             ; can try implementing this to make ppl walk more rational, but may create traffic jam
    ]
    [
      set patience patience + 1
    ]
  ask patch-here [ set capacity count turtles-here ]                                 ; update the local capacity of this patch after moving
end

to random-walk
  move-to patch-here
  ;rt random-float 360
  let p one-of neighbors with [ (dist >= 0) or (dist <= 0) ]             ; pick any neighbors that is valid to move
  if p != nobody and pcolor != black [
    face p
    ;fd (speed-step speed)
  ]
  set can-fd? true
  check-capacity-by-color
  ;move-and-update

end

to capacity-walk
  ;let pNeighbors neighbors with [ capacity >= 0 ]       ; Pick only patches with a valid number (i.e. NOT NaN)
  let pNeighbors neighbors with [ (dist >= 0) or (dist <= 0) ]
  move-to patch-here
  ;if can-fd? = false [
    let p min-one-of pNeighbors [capacity]                            ; most efficient run, produce a single line of ants
    if p != nobody and pcolor != black [
      face p
      ;fd (speed-step speed)
      set can-fd? true
    ]
  ;]
end

to-report calc-speed [current_cap]
  let x 0
  let density (current_cap / (raster-size * raster-size))                                ; density per m2 = capacity (i.e. ppl per patch) / (raster-size ^ 2) --> 4 m2
  if density = 0 [ set x max-speed ]
  if density > 0 [
    let pmax max-capacity                                                                         ; maximum density where speed = 0 m/s, pmax = 5.4 according to Wirz et al. 2013
    let gamma (- 1.913)                                                                  ; a fit parameter of the Wiedmann's fundamental diagram
    set x (max-speed * (1 - exp(gamma * ((1 / density) - (1 / pmax)))))
    ; allow some people get away even if max capacity is exceed
    if x < 0.037 [ set x 0.037 ]                                                         ; Round to 0.037 m/s (the speed @ 5 ppl/m2) to avoid negative speed value
  ]
  report x

end

to-report speed-step [in-speed]                                  ; convert the speed in m/s to how much step to forward
  let step (in-speed * seconds-per-tick / raster-size)                                      ; step = speed in m/s * time in s / raster-size in m
  if step > 1 [ set step 1 ]                                                               ; even if the speed exceeds 1 step/tick, make it a whole step to avoid people going to NaN
  if step <= 0.51 [ set step 0.51 ]                                                          ; make it at least half a step so they can move out from the patch center to the next
  report step
end

to update-speed
  ask patches with [ (dist >= 0) or (dist <= 0) ] [
    let pNeighbors neighbors with [ (dist >= 0) or (dist <= 0) ]                           ; get the neighbors with valid distance (i.e. valid on-route patch)
    let pCount count neighbors with [(dist >= 0) or (dist <= 0) ]                          ; get neighbor count
    let total-capacity (capacity + count turtles-on pNeighbors)                            ; total capacity = capacity at focal patch + capacities in 8 neighbors
    let avg-capacity 1
    if pCount > 0   [ set avg-capacity (total-capacity / pCount)]                                             ; average capacity of a 3x3 local neighborhood
    set speed calc-speed avg-capacity
  ]
  ;ask patch 1667 222 [ set speed max-speed ]                         ; This is located at the exit of VP, still need?
end

to update-capacity
  ask patches  [ set capacity count turtles-here ]
end

to check-capacity
  if [capacity] of patch-ahead 1 >= max-capacity-per-patch [                 ; if the capacity of patch-ahead is full, then move to the patch either @ left-ahead or right-ahead
    set can-fd? false
    let a 0
    let b 0
    if ([dist] of patch-right-and-ahead 45 1 >= 0) or ([dist] of patch-right-and-ahead 45 1 <= 0) [ set a 5 ]          ; if the patch @ right-ahead is on-route (i.e. capacity != -1)
    if ([dist] of patch-left-and-ahead 45 1 >= 0) or ([dist] of patch-left-and-ahead 45 1 <= 0) [ set b 5 ]          ; if the patch @ right-ahead is on-route (i.e. capacity != -1)
    if (a > 0) or (b > 0) [
      set wall-turn-check random 9
      ifelse (wall-turn-check + a - b) >= 5 [
        if [capacity] of patch-right-and-ahead 45 1 < max-capacity-per-patch [      ; if the patch @ right-ahead is on-route and has capacity
          face patch-right-and-ahead 45 1
          set can-fd? true
        ]
      ]
      [
        if [capacity] of patch-left-and-ahead 45 1 < max-capacity-per-patch [      ; if the patch @ left-ahead is on-route and has capacity
          face patch-left-and-ahead 45 1
          set can-fd? true
        ]
      ]
    ]
  ]
end

to check-capacity-VP
  if [capacity] of patch-ahead 1 >= max-capacity-per-patch [                 ; if the capacity of patch-ahead is full, then move to the patch either @ left-ahead or right-ahead
    set can-fd? false
    let a 0
    let b 0
    if ([pcolor] of patch-right-and-ahead 45 1 = cyan) or ([pcolor] of patch-right-and-ahead 45 1 = cyan) [ set a 5 ]          ; if the patch @ right-ahead is valid
    if ([pcolor] of patch-left-and-ahead 45 1 = cyan) or ([pcolor] of patch-left-and-ahead 45 1 = cyan) [ set a 5 ]          ; if the patch @ left-ahead is valid
    if (a > 0) or (b > 0) [
      set wall-turn-check random 9
      ifelse (wall-turn-check + a - b) >= 5 [
        if [capacity] of patch-right-and-ahead 45 1 < max-capacity-per-patch [      ; if the patch @ right-ahead is on-route and has capacity
          face patch-right-and-ahead 45 1
          set can-fd? true
        ]
      ]
      [
        if [capacity] of patch-left-and-ahead 45 1 < max-capacity-per-patch [      ; if the patch @ left-ahead is on-route and has capacity
          face patch-left-and-ahead 45 1
          set can-fd? true
        ]
      ]
    ]
  ]
end

to check-capacity-by-color
  if [capacity] of patch-ahead 1 >= max-capacity-per-patch [                 ; if the capacity of patch-ahead is full, then move to the patch either @ left-ahead or right-ahead
    set can-fd? false
    let a 0
    let b 0
    if ([pcolor] of patch-right-and-ahead 45 1 = cyan) or ([pcolor] of patch-right-and-ahead 45 1 = cyan) [ set a 5 ]          ; if the patch @ right-ahead is valid
    if ([pcolor] of patch-left-and-ahead 45 1 = cyan) or ([pcolor] of patch-left-and-ahead 45 1 = cyan) [ set a 5 ]          ; if the patch @ left-ahead is valid
    if (a > 0) or (b > 0) [
      set wall-turn-check random 9
      ifelse (wall-turn-check + a - b) >= 5 [
        if [capacity] of patch-right-and-ahead 45 1 < max-capacity-per-patch [      ; if the patch @ right-ahead is on-route and has capacity
          face patch-right-and-ahead 45 1
          set can-fd? true
        ]
      ]
      [
        if [capacity] of patch-left-and-ahead 45 1 < max-capacity-per-patch [      ; if the patch @ left-ahead is on-route and has capacity
          face patch-left-and-ahead 45 1
          set can-fd? true
        ]
      ]
    ]
  ]
end

@#$#@#$#@
GRAPHICS-WINDOW
59
316
2187
679
-1
-1
1.223
1
14
1
1
1
0
1
1
1
0
1733
0
289
1
1
1
ticks
30.0

BUTTON
86
36
185
74
Setup!
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

PLOT
1370
42
1720
262
Protesters Count
Iteration
Count
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"On-scene" 1.0 0 -2674135 true "" "plot count turtles"
"Left" 1.0 0 -955883 true "" "plot count-leave"
"Late" 1.0 0 -10899396 true "" "plot count-late"
"Finished" 1.0 0 -7500403 true "" "plot count-finished"
"Total" 1.0 0 -13345367 true "" "plot count protesters + count-finished + count-leave"
"Die" 1.0 0 -16777216 true "" "plot count-die"
"Done" 1.0 0 -5825686 true "" "plot count-finished + count-leave"

BUTTON
86
83
184
121
Go!
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
415
85
590
118
max-speed
max-speed
0
3
1.4
0.1
1
m/s
HORIZONTAL

SWITCH
220
36
400
69
Other-entrance?
Other-entrance?
0
1
-1000

MONITOR
896
158
1026
203
Protesters On-scene
count protesters
3
1
11

SLIDER
413
35
611
68
max-capacity
max-capacity
0.1
10
5.4
0.1
1
People / m^2
HORIZONTAL

INPUTBOX
74
131
200
191
total-protesters
265000.0
1
0
Number

MONITOR
895
99
1021
144
Finished Protesters
count-finished
17
1
11

INPUTBOX
603
110
675
171
raster-size
2.0
1
0
Number

MONITOR
1035
215
1195
260
Total Protesters Simulated
count protesters + count-finished + count-leave + count-die
17
1
11

PLOT
1729
39
2107
259
Patch variables
Iteration
Mean
0.0
10.0
0.0
5.0
true
true
"" ""
PENS
"Capacity (ppl/m2)" 1.0 0 -13345367 true "" "plot ((count protesters)/(count patches with [capacity > 0]))/(raster-size * raster-size)"
"Speed (m/s)" 1.0 0 -2674135 true "" "plot mean [speed] of patches with [capacity > 0]"
"Patience" 1.0 0 -7500403 true "" "plot mean [patience] of protesters"

INPUTBOX
683
112
778
174
seconds-per-tick
3.0
1
0
Number

MONITOR
902
40
1008
85
Protestors in VP
count protesters with [name = \"VP\"]
17
1
11

MONITOR
788
99
888
144
Lost Protesters
count-die
17
1
11

SWITCH
220
86
402
119
Early-departure?
Early-departure?
0
1
-1000

MONITOR
789
159
889
204
Early Departure
count-leave
17
1
11

SLIDER
413
133
589
166
leave-rate
leave-rate
0
90
70.0
10
1
%
HORIZONTAL

SLIDER
415
180
590
213
entry-rate
entry-rate
0
4000
2000.0
100
1
ppl/min
HORIZONTAL

SLIDER
602
182
775
215
time-late-CWB
time-late-CWB
0
180
20.0
1
1
min
HORIZONTAL

SLIDER
603
226
776
259
time-late-WC
time-late-WC
0
180
40.0
1
1
min
HORIZONTAL

SLIDER
412
226
591
259
time-late-Other
time-late-Other
0
180
25.0
1
1
min
HORIZONTAL

MONITOR
1033
40
1126
85
Sim. Time (hr)
(ticks * seconds-per-tick) / 3600
2
1
11

INPUTBOX
619
38
775
99
VP-Protesters
1355.0
1
0
Number

MONITOR
899
216
1027
261
Protesters needed
total-protesters - (count protesters + count-finished + count-leave)
17
1
11

INPUTBOX
73
199
197
259
Simulation-time-min
480.0
1
0
Number

INPUTBOX
785
35
887
95
VP-EndTime-min
600.0
1
0
Number

INPUTBOX
220
178
397
238
Lockhart-YeeWor-StartTime-min
90.0
1
0
Number

INPUTBOX
219
248
399
308
Lockhart-YeeWor-Duration-min
60.0
1
0
Number

SWITCH
220
137
399
170
Tributaries-open?
Tributaries-open?
0
1
-1000

MONITOR
1040
102
1192
147
Estimated finished (hr)
ticks-last-finished * 3 / 3600
2
1
11

MONITOR
1072
159
1190
204
Protester % Done
precision percent-done 2
17
1
11

MONITOR
1133
40
1191
85
Time %
precision percent-time 2
17
1
11

MONITOR
788
216
894
261
Late protesters
count-late
17
1
11

MONITOR
1035
265
1174
310
Time 1st finished (hr)
ticks-first-finished * 3 / 3600
2
1
11

MONITOR
896
269
1029
314
Rally Time Error (%)
dblError
17
1
11

MONITOR
1203
42
1296
87
Left @ CWB
count-leave-CWB
17
1
11

MONITOR
1205
100
1280
145
Left @ WC
count-leave-WC
17
1
11

MONITOR
1203
158
1318
203
Left @ Admiralty
count-leave-Admiralty
17
1
11

MONITOR
1203
210
1329
255
Entry from CWB
count-entry-CWB
17
1
11

MONITOR
1180
266
1283
311
Entry from WC
int count-entry-WC
17
1
11

MONITOR
1289
266
1387
311
Entry from VP
count-entry-VP
17
1
11

PLOT
2125
50
2473
253
Entry-Leave Plot
Iteration
Count
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Entry-VP" 1.0 0 -16777216 true "" "plot count-entry-VP"
"Entry-CWB" 1.0 0 -10141563 true "" "plot count-entry-CWB"
"Entry-WC" 1.0 0 -13840069 true "" "plot count-entry-WC"
"Leave-CWB" 1.0 0 -3425830 true "" "plot count-leave-CWB"
"Leave-WC" 1.0 0 -5509967 true "" "plot count-leave-WC"
"Leave-Admiralty" 1.0 0 -11033397 true "" "plot count-leave-Admiralty"

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
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
