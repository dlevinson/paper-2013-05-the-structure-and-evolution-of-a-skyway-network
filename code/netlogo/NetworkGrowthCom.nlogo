;;
;; Model: agent-based modeling the network growth and the Minneapolis skyway network
;; The forumlation of the models can be found in the papers
;; "A positive theory of network connectiviy" and
;; "The structure and dynamics of a skyway network"
;;  Date: Dec 12,  2012
;;  Questions about the code can be sent to Arthur Huang at huang284@umn.edu 
;;

extensions [gis]
globals 
  [  
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; global variables   ;;;;;;;;;;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   nodes-dataset skyways-dataset block-dataset
   infinity  ;; a very large number
   sequence 
   rounds
   ;cost
   roadness;; list of nodes that have the minimum x or y
              ;; this is used to calculate roadness
   totalEfficiency  ;; total network efficiency
   avgCoeff  ;; average clustering coefficient 
   node-start  ;; a node to start a link
   node-end    ;; a node at the end of a link 
   ;unitedgecost
   outputlinks
   matchratio
   background
   ;unitedgecost
   unitbenefit_np  ;; unit benefit 
   ;unitbenefit_p
  ]
  
  
;;agents in the skyway paper
breed [buildings building]
breed [skyways skyway]
;;agents in the network connectivity paper
breed [locations location]

;;;;;;;;;;;;;;;;;;;;;;;;
;;; agent in the skyway model ;;;
;;;;;;;;;;;;;;;;;;;;;;;;
;;varaiables of the network segments
skyways-own
[
    origin
    destination
    len
    year
 ]
;;;;;;;;;;;;;;;;;;;;;;;;
;;; agent in the skyway model ;;;
;;;;;;;;;;;;;;;;;;;;;;;;
;; variables of the segments
buildings-own
[
  ;;nodes-along-shortest-path ;; list of nodes along the shortest path (including the target node) given a fixed source and a target 
  distance-from-other-turtles ;; weight of each edge (0 stands for connecting to itself, infinity stands for no connection)
  profit-list ;; list of profits to each node
  node-candidate-list ;; list of nodes to be connected for each round 
                      ;; the sequence of the members in the list is the same as the profit-list
  accessiblity  ;; profit from the whole network
  ;cost
  straightness
  nodelist ;; list of nodes to be added (corresponding to the profit list)
  sum_of_straightness
  information  
  marginalProfitlist
  ;profitInLastRound
  prev   ;; list of previous nodes in a shortest path
  ;; all the nodes on the shortest path
  shortest-path-nodes 
  connectedList ;; a list of that can be connected (it documents the nearest four nodesw)
  employee  ;; employees in a building
  ;searched  ;; index to see if a building has been searched before in comparing generated network with actual network
   space1962  space1963  space1964  space1965  space1966  space1967  space1968  space1969  space1970  space1971  space1972  space1973  space1974  space1975  space1976  space1977  space1978 
   space1979  space1980  space1981  space1982  space1983  space1984  space1985  space1986  space1987  space1988  
   space1989  space1990  space1991  space1992  space1993  space1994  space1995  space1996  space1997  space1998  
   space1999  space2000  space2001  space2002  
   
   space
   blockID
]  


;;;;;;;;;;;;;;;;;;;;;;;;
;;; agent in the network connectivity model ;;;
;;;;;;;;;;;;;;;;;;;;;;;;
locations-own
[
  ;;nodes-along-shortest-path ;; list of nodes along the shortest path (including the target node) given a fixed source and a target 
  distance-from-other-turtles ;; weight of each edge (0 stands for connecting to itself, infinity stands for no connection)
  profit-list ;; list of profits to each node
  node-candidate-list ;; list of nodes to be connected for each round 
                      ;; the sequence of the members in the list is the same as the profit-list
  accessiblity  ;; profit from the whole network
  straightness
  nodelist ;; list of nodes to be added (corresponding to the profit list)
  sum_of_straightness
  information  
  marginalProfitlist
  ;profitInLastRound
  prev   ;; list of previous nodes in a shortest path
  ;; all the nodes on the shortest path
  shortest-path-nodes 
  connectednesList ;; a list of nodes that have  not been connected
]


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;set up the landscape given different choices  ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to setup
  
  clear-all
  clear-patches
  clear-drawing
  clear-all-plots
  clear-output
  set rounds 0
  
  set infinity 999999  ;; set infinity to be a very large number
  set totalEfficiency  0
  ask patches [set pcolor white]
  ;;prepare the GIS data 
  
  set-default-shape locations "circle"
  set-default-shape buildings "circle"

  ;; sprout breed number [commands]: create a lcoation 
  ask patches with [abs pxcor < (grid-size / 2) and abs pycor < (grid-size / 2)] [ sprout-locations 1 [ set color green ] ]
  ask locations [setxy ( xcor * scale) ( ycor * scale)  set accessiblity 0  set marginalProfitlist [] set distance-from-other-turtles [] set shortest-path-nodes  []  set nodelist [] ]
  
  
  ifelse Scenario = "Single center"
  [ 
      ask locations [    if xcor = 0 and ycor = 0   [ set color red  set size 1]   ]        
  ]
  [ 
      ifelse Scenario = "Two centers"
      [
          ask locations [    if ( xcor = -1 * int(grid-size / 4) * scale  and ycor = 0) or ( xcor = int(grid-size / 4) * scale and ycor = 0)  [ set color red  set size 1] ]    
      ]
      [
         ifelse Scenario = "Four centers"
         [  
            ask locations [  if (xcor = -1 * int(grid-size / 4) * scale and ycor = 0) or ( xcor =  int(grid-size / 4) * scale and ycor = 0) or (xcor = 0 and ycor = -1 * int(grid-size / 4) * scale) or (xcor  = 0 and ycor = int(grid-size / 4) * scale)  [ set color red  set size 1] ]
         ]
         [
            ifelse Scenario =  "Nine centers"
            [
                ask locations [  
                  
                if (xcor = -1 * int(grid-size / 4) * scale and ycor = 0) or ( xcor =  int(grid-size / 4) * scale and ycor = 0) or (xcor = 0 and ycor = -1 * int(grid-size / 4) * scale) or (xcor  = 0 and ycor = int(grid-size / 4) * scale)  
                or   (xcor = -1 * int(grid-size / 4) * scale and ycor = int(grid-size / 4) * scale) or  (xcor =  int(grid-size / 4) * scale and ycor = int(grid-size / 4) * scale) or ( xcor  = 0 and ycor = 0) 
                or   (xcor =  int(grid-size / 4) * scale and ycor = int(grid-size / 4) * scale) or (xcor =  int(grid-size / 4) * scale and ycor = -1 * int(grid-size / 4) * scale) or (xcor =  -1 * int(grid-size / 4) * scale and ycor = -1 * int(grid-size / 4) * scale)
                [ set color red  set size 1] ]
       
            ]
            [
              if Scenario = "Minneapolis skway"
              [
                
                  clear-turtles
                   set nodes-dataset gis:load-dataset "centroids_new2_SpatialJoin6.shp"
                   set skyways-dataset  gis:load-dataset "downtown_skyways2.shp"
                   set block-dataset  gis:load-dataset "potentialblocks.shp"
                   ;gis:set-world-envelope ((gis:envelope-of skyway-dataset))
                   gis:set-world-envelope (gis:envelope-union-of (gis:envelope-of nodes-dataset) (gis:envelope-of skyways-dataset) (gis:envelope-of  block-dataset ) )  

                 display-buildings
                 import-skyways
                 construct-connectedList
              ]
            ]
       
         ]
     
     ]
      
 ]
    
end


to import-skyways
   ask skyways [die]
   
   foreach gis:feature-list-of skyways-dataset
   [
      let centroid gis:location-of gis:centroid-of ?
      if not empty? centroid
      [
         create-skyways 1
         [ 
              set origin   gis:property-value ? "new_origin"
              set destination gis:property-value ? "new_dest"
              set len gis:property-value ? "length"
              set year gis:property-value ? "YEAR"
              ;output-show origin output-show destination
         ]
       ]
   ]

end   
   
   
to display-buildings
  
   ask locations [die]
   ask buildings [die]  
   foreach gis:feature-list-of nodes-dataset
   [  ;gis:set-drawing-color blue
      ;gis:fill ? 3.0
      ;let location gis:location-of (first (first (gis:vertex-lists-of ?)))
      let centroid gis:location-of gis:centroid-of ?
      if not empty? centroid
       ; create one building and copy  the xcor and ycor to the building
      [  
        create-buildings 1 
        [ 
            ;set employee em
            ;set pcolor red
            gis:set-drawing-color red
            gis:fill ? 3.0
            set xcor item 0 centroid
            set ycor item 1 centroid
            set size 0
            ; import the property value from "Employee"
            set employee gis:property-value ? "EMP05"
            set blockID  gis:property-value ?  "BLOCKID"
            set  space1962  gis:property-value ?  "space1962"
            set  space1963  gis:property-value ?  "space1963"
            set  space1964  gis:property-value ?  "space1964"
            set  space1965  gis:property-value ?  "space1965"
            set  space1966  gis:property-value ?  "space1966"
            set  space1967  gis:property-value ?  "space1967"
            set  space1968  gis:property-value ?  "space1968"
            set  space1969  gis:property-value ?  "space1969"
            set  space1970  gis:property-value ?  "space1970"
            set  space1971  gis:property-value ?  "space1971"
            set  space1972  gis:property-value ?  "space1972"
            set  space1973  gis:property-value ?  "space1973"
            set  space1974  gis:property-value ?  "space1974"
            set  space1975  gis:property-value ?  "space1975"
            set  space1976  gis:property-value ?  "space1976"
            set  space1977  gis:property-value ?  "space1977"
            set  space1978  gis:property-value ?  "space1978"
            set  space1979  gis:property-value ?  "space1979"
            set  space1980  gis:property-value ?  "space1980"
            set  space1981  gis:property-value ?  "space1981"
            set  space1982  gis:property-value ?  "space1982"
            set  space1983  gis:property-value ?  "space1983"
            set  space1984  gis:property-value ?  "space1984"
            set  space1985  gis:property-value ?  "space1985"
            set  space1986  gis:property-value ?  "space1986"
            set  space1987  gis:property-value ?  "space1987"
            set  space1988  gis:property-value ?  "space1988"
            set  space1989  gis:property-value ?  "space1989"
            set  space1990  gis:property-value ?  "space1990"
            set  space1991  gis:property-value ?  "space1991"
            set  space1992  gis:property-value ?  "space1992"
            set  space1993  gis:property-value ?  "space1993"
            set  space1994  gis:property-value ?  "space1994"
            set  space1995  gis:property-value ?  "space1995"
            set  space1996  gis:property-value ?  "space1996"
            set  space1997  gis:property-value ?  "space1997"
            set  space1998  gis:property-value ?  "space1998"
            set  space1999  gis:property-value ?  "space1999"
            set  space2000  gis:property-value ?  "space2000"
            set  space2001  gis:property-value ?  "space2001"
            set  space2002  gis:property-value ?  "space2002"
            
         ]
          
      ]
 
      
   ]  
  
      let node-count count buildings

       ask buildings 
       [  set accessiblity 0  set marginalProfitlist [] set distance-from-other-turtles [] 
          set shortest-path-nodes  []  set nodelist [] set connectedList []  set space 0
        ]

end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;; set up the connection list of each buiding;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; rule: each building that can only connect to its adjacent buildings with segments pararelling with the grid;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to construct-connectedList
  
  let id 0
  let node-count count buildings

  
ask building 39 [ set connectedList lput 100 connectedList  set connectedList lput 40 connectedList ]
  ask building 100 [ set connectedList lput 39 connectedList  set connectedList lput 99 connectedList set connectedList lput 35 connectedList  set connectedList lput 97 connectedList]
  ask building 35 [ set connectedList lput  32 connectedList  set connectedList lput 92 connectedList set connectedList lput 95 connectedList set connectedList lput 100 connectedList]
  ask building 32 [ set connectedList lput  35 connectedList  set connectedList lput  91 connectedList ]
  ;ask building 23  [ set connectedList lput 20  connectedList  set connectedList lput 87  connectedList set connectedList lput 91 connectedList ]
  ask building 23  [ set connectedList [] ]
  
  ask building 91 [ set connectedList lput 87 connectedList  set connectedList lput 92  connectedList set connectedList lput 32 connectedList ]
  
  ask building 55 [  set connectedList lput 52   connectedList set connectedList lput 56  connectedList  set connectedList lput 67   connectedList]
  
  ;ask building 67  [ set connectedList lput  66 connectedList  set connectedList lput 55  connectedList set connectedList lput 68  connectedList  set connectedList lput  73  connectedList]
  
  ask building 73 [  set connectedList lput  67 connectedList set connectedList lput 74  connectedList  set connectedList lput 81   connectedList]

  ;ask building 20  [  set connectedList lput 86  connectedList   set connectedList lput 23 connectedList ]
  ask building 20 [ set connectedList []]
  
  
  ask building 80   [ set connectedList lput  79 connectedList  set connectedList lput 81  connectedList set connectedList lput 87 connectedList ]
  ask building 86  [  set connectedList lput 72  connectedList set connectedList lput 79 connectedList set connectedList lput 87  connectedList ]
  ask building 72 [set connectedList lput  86 connectedList set connectedList lput  79  connectedList  set connectedList lput 64   connectedList]
  ask building 14 [  set connectedList lput 65   connectedList  set connectedList lput 16  connectedList  set connectedList lput  72  connectedList ]
  ask building 64 [  set connectedList lput 72  connectedList  set connectedList lput 65  connectedList  set connectedList lput 63  connectedList ]
  ask building 63 [ set connectedList lput 64  connectedList set connectedList lput  101 connectedList  set connectedList lput 62  connectedList ]
  ask building 62 [ set connectedList lput 63  connectedList  set connectedList lput 61  connectedList]
  ask building 61 [ set connectedList lput 62  connectedList ]
  ask building 2  [ set connectedList [] ]
  ask building 1 [ set connectedList [] ]
  ask building 3 [ set connectedList []  ]
  ask building 0 [ set connectedList [] ]
  ;ask building 26 [ set connectedList lput 43 connectedList  set connectedList lput 42  connectedList  set connectedList lput 41  connectedList ]
  ask building 26 [set connectedList []]
  ask building 43 [ set connectedList lput  44 connectedList  ]
  ask building 41  [ set connectedList lput 42 connectedList set connectedList lput 27  connectedList ]
  ask building 27 [  set connectedList lput 41 connectedList]
  ask building 7 [set connectedList [] ]
  ask building 10 [ set connectedList lput 7 connectedList set connectedList lput 8 connectedList set connectedList lput 46 connectedList  set connectedList lput 47 connectedList set connectedList lput 13 connectedList ]
  ask building 13 [ set connectedList []]
  ask building 15 [ set connectedList [] ]
  ask building 18  [ set connectedList [] ]
  ask building 19  [ set connectedList [] ]
  ask building 22 [ set connectedList [] ]
  ask building 31 [ set connectedList lput 71 connectedList set connectedList lput 34 connectedList ]
  ask building 34 [ set connectedList lput 31 connectedList set connectedList lput 78 connectedList  ]
  ask building 36 [ set connectedList lput 85 connectedList set connectedList lput 78  connectedList  ]
  ask building 37 [ set connectedList lput 85 connectedList set connectedList lput 24 connectedList set connectedList lput 38 connectedList ]
  ask building 38 [ set connectedList lput 37  connectedList set connectedList lput 94 connectedList]
  ask building 25 [ set connectedList [] ]
  ask building 104 [set connectedList lput 102 connectedList ]
  ask building 98 [ set connectedList lput 102  connectedList set connectedList lput 103 connectedList  ]
  ask building 102 [ set connectedList lput 104  connectedList set connectedList lput 96 connectedList set connectedList lput 98 connectedList]
  ask building 40 [ set connectedList lput 99 connectedList set connectedList lput 39  connectedList ]
  
  ask building 65 [ set connectedList lput 64  connectedList set connectedList lput 101  connectedList  set connectedList lput 66 connectedList]
  
  ask building 67 [ set connectedList lput 55 connectedList set connectedList lput 66 connectedList   set connectedList lput  73  connectedList   set connectedList lput 68 connectedList ]
  ask building 73 [  set connectedList lput 67  connectedList   set connectedList lput 81  connectedList  set connectedList lput 74 connectedList ]
  
  ask building 79 [ set connectedList lput 72 connectedList   set connectedList lput 86  connectedList set connectedList lput 80 connectedList]
  
  ask building 80 [ set connectedList lput 79 connectedList   set connectedList lput 87 connectedList   set connectedList lput 81 connectedList ]
    
  ask building 88 [  set connectedList lput 81 connectedList  set connectedList lput 87 connectedList   set connectedList lput 92 connectedList  set connectedList lput 89  connectedList ]
  
  ask building 40 [  set connectedList lput 99 connectedList   set connectedList lput 39 connectedList ]
  
  ask building 36 [  set connectedList lput 78 connectedList   set connectedList lput 85 connectedList]
  
  ask building 100 [ set connectedList lput 35  connectedList  set connectedList lput 97 connectedList  set connectedList lput 99 connectedList  set connectedList lput 39 connectedList]
    
  ask building 103 [  set connectedList lput 97 connectedList  set connectedList lput 99 connectedList   set connectedList lput 98 connectedList]
  
  ask building 14 [ set connectedList []]
  
  ask building 16 [ set connectedList []]
    
  ask building 51 [  set connectedList lput 47 connectedList  set connectedList lput 50 connectedList  set connectedList lput 30 connectedList  ]
  
  ask building 30 [  set connectedList lput 51 connectedList  set connectedList lput 60 connectedList ]
  
  ask building 77  [  set connectedList lput 76 connectedList  set connectedList lput 85 connectedList  set connectedList lput 78 connectedList ]
  
  ask building 28 [   set connectedList lput 52 connectedList   ]
  
  ask building 42  [  set connectedList lput 41 connectedList  set connectedList lput 44 connectedList ]

  ask building 66 [  set connectedList lput 65 connectedList  set connectedList lput 67 connectedList ]

  ask building 87 [ set connectedList lput 80 connectedList  set connectedList lput 86 connectedList  set connectedList lput 91 connectedList  set connectedList lput 88 connectedList]
  
  ask building 81 [  set connectedList lput 73 connectedList   set connectedList lput 80 connectedList  set connectedList lput 88 connectedList  set connectedList lput 82 connectedList]
  
  ask building 96 [ set connectedList lput 93 connectedList set connectedList lput 95 connectedList  set connectedList lput 103 connectedList set connectedList lput 102 connectedList]
 
  ask building 16 [ set connectedList lput 66 connectedList  set connectedList lput 14 connectedList set connectedList lput 79 connectedList set connectedList lput 73 connectedList   ]
  
  ask building 12 [ set connectedList []]
  
  ask building 101 [ set connectedList lput 63  connectedList set connectedList lput 65  connectedList]
  
  ask building 6 [ set connectedList []]
  
  ask building 9 [ set connectedList []]
  
  ask building 52  [ set connectedList lput 28 connectedList set connectedList lput 29 connectedList set connectedList lput 55 connectedList]
  
  ask building 5 [ set connectedList []]
  
  ask building 4  [ set connectedList []]
 
  ask building 29 [ set connectedList lput 52 connectedList   set connectedList lput 56 connectedList set connectedList lput 53 connectedList ]
  
  ask building 48  [ set connectedList lput 44 connectedList set connectedList lput 49 connectedList set connectedList lput  53 connectedList ]
  
  ask building 8 [ set connectedList []]
  
  ask building 45 [ set connectedList lput  44 connectedList set connectedList lput 49 connectedList  set connectedList lput 46 connectedList ]
  
  ask building 46 [ set connectedList lput 45 connectedList set connectedList lput 50 connectedList set connectedList lput 47 connectedList ]

  ask building 10 [ set connectedList []]
  
  ask building 47 [ set connectedList lput 46 connectedList set connectedList lput 51 connectedList  ]
  
  ask building 60 [ set connectedList lput 30 connectedList set connectedList lput 59 connectedList set connectedList lput 71 connectedList ]
  
  ask building 21 [ set connectedList []]

  ask building 70 [ set connectedList lput 58 connectedList set connectedList lput 69 connectedList set connectedList lput 76 connectedList ]
  
  ask building 59 [ set connectedList lput 58 connectedList  set connectedList lput 60 connectedList ]
  
  ask building 71  [ set connectedList lput 60 connectedList  set connectedList lput 31 connectedList set connectedList lput 78 connectedList ]
  
  ask building 24 [  set connectedList [] ]
  
  ask building 94 [ set connectedList lput  93 connectedList set connectedList lput 102 connectedList set connectedList lput 38 connectedList  ]
  
  ask building 90 [set connectedList lput 83 connectedList set connectedList lput 89 connectedList set connectedList lput 93 connectedList ]
 
  ask building 17 [ set connectedList []] 
  
  ask building 50 [ set connectedList lput  46 connectedList set connectedList lput  49 connectedList set connectedList lput  51 connectedList ] 
  
  ask building 54 [   set connectedList lput 49 connectedList set connectedList lput  53 connectedList set connectedList lput 58 connectedList]
  
  ask building 84 [   set connectedList lput 76 connectedList   set connectedList lput 83 connectedList set connectedList lput 85 connectedList]
 
  while [ id  < node-count]
  [
     
     if ( id != 39 AND id !=  100 AND id !=  35 AND id != 32 AND id !=  23 AND id != 20 AND id != 80 AND id != 86 AND id != 72 AND id != 14 AND id != 64 AND id != 63
     AND id != 62 AND id != 61 AND id != 1 AND id != 3 AND id != 0 AND id != 26 AND id != 41 AND id != 27 AND id != 7 AND id != 10 AND id != 13 AND id != 15 AND id != 18 AND id != 19 AND id != 22 AND id != 31
     AND id != 34 AND id != 36 AND id != 37 AND id != 38 AND id != 25 AND id != 104 AND id != 98 AND id != 102 AND id != 40 AND id != 55 AND id != 67 AND id != 73 AND id != 43 AND id != 67 AND id != 73 AND id != 80 AND id != 88
     AND id != 40 AND  id != 36  AND id != 100 AND id != 103 AND id != 51 AND id != 30 AND id != 77 AND id != 28 AND id != 42 AND id != 79  AND id != 66 AND id != 87 AND id != 81 AND id != 96 AND id != 16 AND id != 91
      AND id != 14 AND id != 16 AND id != 65 AND id != 12 AND id != 101 AND id != 6 AND id != 52 AND id != 5 AND id != 4 AND id != 29 AND id != 48 AND id != 8 AND id != 45 AND id != 46 AND id != 10
      AND id != 7 AND id != 47 AND id != 60 AND id != 21 AND id != 70  AND id != 59 AND id != 71 AND id != 24 AND id != 94 AND id != 90 AND id != 17 ANd id != 50 ANd id != 54 And id != 84)  
    
        [ ask building id [set connectedList [who] of  min-n-of 5  buildings[distance myself]]  ]
     
     set id id + 1 
  ]
  
end



to begin-skyway-competition
   let i 0
    let j 0
    let k 0
    let p 0
    let s 0
    let t 0
    let dist 0
    let id 0
    let connectNode 0
    set sequence []
    let node-count count buildings
    ask buildings [set accessiblity 0  set marginalProfitlist [] set distance-from-other-turtles [] set shortest-path-nodes  []  set nodelist [] ]
    ;; make the squence of moving random
    while [i < node-count]
    [
        set sequence lput i sequence
        set i i + 1
    ]
   
     ;; print out sequence of moving
     output-show sequence
    
    set i 0
    while [ i < node-count]
    [ 
       ;ask turtles [output-show distance-from-other-turtles ]
       let accessiblity_no_newlink  0
       set id (item i sequence )
       
       ;; initialize distance set for al turtles
       
        initialize-distance-set
        
        ask building id [
           find-skywaypath-lengths id
           set accessiblity_no_newlink accessiblity 
           ;output-show "accessiblity_no_newlink"  
           ;output-show accessiblity_no_newlink
        ]
        ask building id  [ set accessiblity 0 set marginalProfitlist [] set nodelist []   
       ; output-show "size of connectedlist "
       ; output-show length [connectedlist] of building id
          
        ]
        
 
       let m 0

       
       while [m < length [connectedlist] of building id]
       [
         
            set t item m ([connectedList] of building id)
            
            if [ link-neighbor? building t ] of building id  = false and id != t
            [  ask building id [ create-link-with building t [ set color red] ] 
              
              find-network-distance-skyway id 
              
               ask building id  
               [
                   find-skywaypath-lengths id
                   let cost ( distance (building t) * unitedgecost )
                    set marginalProfitlist lput (accessiblity - accessiblity_no_newlink - cost) marginalProfitlist
                   set nodelist lput t nodelist
                ]
               
               ask link id t [die]
            ]
            

            set m m + 1  
       ]
       

                      
         if [marginalProfitlist] of building id != [] and [nodelist] of building id  != []
        [
        
          let node1 0
          let node2 0
        
           ask building id 
           [
                 
                 if (max marginalProfitlist) > 0
                 [
                  
                    let maxvalue (max marginalProfitlist)
                    set p (position maxvalue marginalProfitlist) 
                    set node1 item p nodelist
                    create-link-with building node1 [set color 63 ]

                     
                 ]                              
           ]
           
           
            ;initialize-distance-set
            
        ]
        
        ;[
         ;      output-show "not connected"
         ;      output-show "building"
         ;      output-show id           
       ; ]
        
        tick   
        
        set i i + 1
        
    ]  
  
  
  
end


to go
  
  ask links [set color black]
   
  ifelse Scenario = "Minneapolis skway"
  [ 
     setupbuildingspace rounds
     begin-skyway-competition 
  ]
  [ begin-gridnetwork-competition]
  
  do-plot
  
  output-show "rounds are:" 
  output-show rounds
  
  set rounds rounds + 1
  
end 



to setupbuildingspace [i]
     if  i = 0
    [ ask buildings [set space space1962]]
    if i = 1
     [ ask buildings [set space space1963]]
    if i = 2
     [ ask buildings [set space space1964]] 
    if i = 3
     [ ask buildings [set space space1965]]     
    if i = 4
     [ ask buildings [set space space1966]] 
    if i = 5
     [ ask buildings [set space space1967]] 
    if i = 6
     [ ask buildings [set space space1968]]  
    if i = 7
     [ ask buildings [set space space1969]]  
    if i = 8
     [ ask buildings [set space space1970]]     
    if i = 9
     [ ask buildings [set space space1971]]   
    if i = 10
     [ ask buildings [set space space1972]]      
    if i = 11
     [ ask buildings [set space space1973]]            
    if i = 12
     [ ask buildings [set space space1974]]  
    if i = 13
     [ ask buildings [set space space1975]]          
    if i = 14
     [ ask buildings [set space space1976]]
    if i = 15
     [ ask buildings [set space space1977]]   
    if i = 16
     [ ask buildings [set space space1978]]  
    if i = 17
     [ ask buildings [set space space1979]]  
    if i = 18
     [ ask buildings [set space space1980]]
    if i = 19
     [ ask buildings [set space space1981]]   
    if i = 20
     [ ask buildings [set space space1982]]        
    if i = 21
     [ ask buildings [set space space1983]]        
    if i = 22
     [ ask buildings [set space space1983]]     
    if i = 23
     [ ask buildings [set space space1984]]      
    if i = 24
     [ ask buildings [set space space1985]]                
    if i = 25
     [ ask buildings [set space space1986]]
    if i = 26
     [ ask buildings [set space space1987]]      
    if i = 27
     [ ask buildings [set space space1988]]     
    if i = 28
     [ ask buildings [set space space1989]]     
     if i = 29
     [ ask buildings [set space space1990]]     
      if i = 30
     [ ask buildings [set space space1991]]
     if i = 31
     [ ask buildings [set space space1992]]
     if i = 32
     [ ask buildings [set space space1993]]     
     if i = 33
     [ ask buildings [set space space1994]]  
     if i = 34
     [ ask buildings [set space space1995]]     
     if i = 35
     [ ask buildings [set space space1996]]    
      if i = 36
     [ ask buildings [set space space1997]]
     if i = 37
     [ ask buildings [set space space1998]]                  
     if i = 38
     [ ask buildings [set space space1999]]     
     if i = 39
     [ ask buildings [set space space2000]]   
     if i = 40
     [ ask buildings [set space space2001]]     
     if i >= 41
     [ ask buildings [set space space2002]]
  
  
end 
  

to initialize-distance-set

 ;; initlialize the initialize-distance-set for all turtles 
  ask buildings [set distance-from-other-turtles [] ]
  let i 0
  let j 0
  let k 0
  let node1 one-of buildings
  let node2 one-of buildings
  let node-count count buildings
  ;; initialize the distance lists
  while [i < node-count]
  [
    set j 0
    while [j < node-count]
    [
      set node1 building i
      set node2 building j
      ;; zero from a node to itself
      ifelse i = j
      [
        ask node1 [ set distance-from-other-turtles lput 0 distance-from-other-turtles ]
      ]
      [
      
        ;; if two nodes are connected, set the distance to be zero because there is no need to build it again;;
        ;; although in some other cases we might want to use another variable to indicate them
        
          ;[ link-neighbor? node1 ] of node2 
         ifelse  [ link-neighbor? node1 ] of node2 = false
         [
            ask node1 [  set distance-from-other-turtles lput infinity distance-from-other-turtles ]
         ]
         [
            ask node1 [  set distance-from-other-turtles lput (distance node2) distance-from-other-turtles ] 
          ] 
       ]
      set j j + 1
    ]
    set i i + 1

 ]
  
end  
   


to initialize-distance-set-gridnetwork

 ;; initlialize the initialize-distance-set for all turtles 
  ask locations [set distance-from-other-turtles [] ]
  let i 0
  let j 0
  let k 0
  let node1 one-of locations
  let node2 one-of locations
  let node-count count locations
  ;; initialize the distance lists
  while [i < node-count]
  [
    set j 0
    while [j < node-count]
    [
      set node1 location i
      set node2 location j
      ;; zero from a node to itself
      ifelse i = j
      [
        ask node1 [ set distance-from-other-turtles lput 0 distance-from-other-turtles ]
      ]
      [
      
        ;; if two nodes are connected, set the distance to be zero because there is no need to build it again;;
        ;; although in some other cases we might want to use another variable to indicate them
          ;[ link-neighbor? node1 ] of node2 
         ifelse  [ link-neighbor? node1 ] of node2 = false
         [
            ask node1 [  set distance-from-other-turtles lput infinity distance-from-other-turtles ]
         ]
         [
            ask node1 [  set distance-from-other-turtles lput (distance node2) distance-from-other-turtles ] 
          ] 
       ]
      set j j + 1
    ]
    set i i + 1

 ]
  
end  
      
to find-network-distance-gridnetwork [id]
  
  ask location id [set distance-from-other-turtles [] ]
  let j 0
  let node-count count locations
  
  while [j < node-count]
  [
       ;set node2 location j
      ifelse id = j
      [
        ask location id [ set distance-from-other-turtles lput 0 distance-from-other-turtles ]
      ]
      [
          ifelse  [ link-neighbor? location id ] of location j = false
          [
             ask location id  [  set distance-from-other-turtles lput infinity distance-from-other-turtles ] 
          ]
          [
             ask location id   [  set distance-from-other-turtles lput (distance location j) distance-from-other-turtles ] 
          ]
      ]  
    
      set j j + 1
  ]
  
end  
 
 
 to find-network-distance-skyway [id]
  
  ask building id [set distance-from-other-turtles [] ]
  let j 0
  let node-count count buildings
  
  while [j < node-count]
  [
      ifelse id = j
      [
        ask building id [ set distance-from-other-turtles lput 0 distance-from-other-turtles ]
      ]
      [
          ifelse  [ link-neighbor? building id ] of building j = false
          [
             ask building id  [  set distance-from-other-turtles lput infinity distance-from-other-turtles ] 
          ]
          [
             ask building id   [  set distance-from-other-turtles lput (distance building j) distance-from-other-turtles ] 
          ]
      ]  
    
      set j j + 1
  ]
 
 
  
end         
   
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;cauclate the revenue of creating a new path;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;   
to find-skywaypath-lengths [m]
   ;; initialize 
   let i 0
   let j 0
   let v 0
   let u 0
   let temp 0
   let newdist 0
   let node-count count buildings
   set prev [] ;; the precedent of each node
   let index [] ; an index indicating whether each node has been added to the graph (true) or not added to the graph (falso)
   
   ;; initialization: set every distance to INFINITY until we discover a path 
   while [i < node-count]
   [
      ;;set distance-from-other-turtles lput (item i [distance-from-immediate-nodes] of turtle m) distance-from-other-turtles 
      ;; keep track of whether the node has been searched or not. 
      set index lput false index
      ;; if the distance infinity then put 0 as the initial value, otherwise put the distance
      ifelse item i [distance-from-other-turtles] of turtle m = infinity 
         [set prev lput 0 prev]
         [set prev lput m prev]
      set i i + 1
   ]   
 
   ;;output-show prev
      ;; distance for the source m to the source m is defined to be zero
   ;;set distance-from-other-turtles replace-item m distance-from-other-turtles 0 
   
   set index replace-item m index true  ;; having been searched

   ;; this loop corresponds to sending out the explorers walking the paths, where
   ;; the step of picking "the vertex, v, with the shorest path to s" corresponds
   ;; to an explorer arriving at an unexplored vertex
   set i 0
   while [i < node-count ]
   [
      ;;find the vertex v in set-of-nodes with smallest dist[] []
      
      set temp infinity 
      set u m 
      set j 0
      
      while [j < node-count]
      [ 
         if (item j index = false) and (item j [distance-from-other-turtles] of turtle m < temp )
         [ 
             set u j
             set temp (item j [distance-from-other-turtles] of turtle m)
         ]
         set j j + 1
      ]
      
      set index replace-item u index true
      
      set j 0
     
      ;;find the shortest path 
      while [ j < node-count]
      [  
          if  ( item j index = false ) and  (item j [distance-from-other-turtles] of turtle u < infinity)
          [
          
            ; ifelse [color] of turtle u = red or [color] of turtle j = red   
            ;     [ set newdist ( item u [distance-from-other-turtles] of turtle m + 2 * item j [distance-from-other-turtles] of turtle u ) ] 
            ;     [ set newdist ( item u [distance-from-other-turtles] of turtle m + item j [distance-from-other-turtles] of turtle u ) ] 
            
             set newdist ( item u [distance-from-other-turtles] of turtle m + item j [distance-from-other-turtles] of turtle u )    
             if newdist < item j [distance-from-other-turtles] of turtle m
             [
                
                ; set [distance-from-other-turtles] of turtle m replace-item j [distance-from-other-turtles] of turtle m newdist
                ;ask turtle m [ set distance-from-other-turtles  j [distance-from-other-turtles] of turtle m newdist ]
                
                ask building m [set distance-from-other-turtles replace-item j [distance-from-other-turtles] of building m newdist ]
                
                set prev (replace-item j prev u)
             ]
          ]
         
          set j j + 1
      ]
      
      set i i + 1
    ]  
  
    ; output-show prev
    
   ;; calculate the profit of the whole network for trutle m 
    set j 0
    let revenue 0

   ask building m [

      while [j < node-count]
      [
         if item j distance-from-other-turtles != infinity and item j distance-from-other-turtles > 0
         [
          
            ;; identify the id of node
            ;; the value of a node is proportional to the number of emploe=yee in that node
            
            set revenue revenue + unitbenefit_p * ([space] of building m / 240) * (item j distance-from-other-turtles ) ^ (- delta)
            
            ;ifelse (m = 46 OR m = 47 OR m = 101 OR m = 60 OR m = 61 OR m = 62 OR m = 63 OR m = 64 Or m = 72 OR m = 96 OR m = 103)
            ;[ set revenue revenue + unitbenefit_p * ([space] of building m / 240) * (item j distance-from-other-turtles ) ^ (- delta) ]
            ;[ set revenue revenue + unitbenefit_np * ([space] of building m / 240) * (item j distance-from-other-turtles ) ^ (- delta)]
            
            
            ;set revenue revenue + unitbenefit * ([employee] of building m) * (item j distance-from-other-turtles ) ^ (- delta)
            ;output-show "distance from nodes"
            ;output-show item j distance-from-other-turtles
            
             ;ifelse j = 67
             
             ;[ set revenue revenue +   w_center * (item j distance-from-other-turtles ) ^ delta
              ; output-show "distance from nodes"
               ;output-show item j distance-from-other-turtles
               
             ;]
             
             ;[ set revenue revenue +  w * (item j distance-from-other-turtles) ^ delta ]
          ]
            
          set j j + 1
     ]
      
      ;output-show "revenue"
      ;output-show revenue
      ;output-show "cost"
      ;output-show cost
      
      set accessiblity revenue
     
    ]
end   
   
   

to begin-gridnetwork-competition
    let i 0
    let j 0
    let k 0
    let p 0
    let s 0
    let t 0
    let dist 0
    let id 0
    let connectNode 0
    set sequence []
    let node-count count locations
    let sizeoflist 0
    ;let downtown 0
    ask locations [set accessiblity 0  set marginalProfitlist [] set distance-from-other-turtles [] set shortest-path-nodes  []  set nodelist [] ]
    
    ;; make the squence of moving random
    while [i < node-count]
    [
        set sequence lput i sequence
        set i i + 1
    ]
    
    ;; make a list of connect
    ;set sequence shuffle sequence 
    ;output-show sequence
    
    set i 0
   while [ i < node-count]
    [ 
       ;ask locations [output-show distance-from-other-turtles ]
       let accessiblity_no_newlink  0
       set id (item i sequence )
       set s 0
       ;; initialize distance set for al locations
        ;initialize-distance-set-gridnetwork
        
        ;output-show "initial distances"
        ;ask locations [output-show distance-from-other-turtles]
        
        
        ;; calculate the profit given the current network
        ;; output it to profit_no_builds
        
        initialize-distance-set-gridnetwork
        
        ask location id [
           find-networkpath-lengths id
           set accessiblity_no_newlink accessiblity 
           ;output-show "accessiblity_no_newlink"  
          ; output-show accessiblity_no_newlink
        ]
        
        
        ask location id  [set accessiblity 0 set marginalProfitlist [] set nodelist []]
        
        ;;revised on Dec. 14, 2011
        
        let m 0
        
        while [ m < node-count]
        [
           if ([distance location m ] of location id = scale) and [ link-neighbor? location m] of location id = false and id != m
            [ ask location id [create-link-with location m [set color red] ]
             
             ;initialize-distance-set-gridnetwork
             find-network-distance-gridnetwork id
             
             ask location id [
               find-networkpath-lengths id
               set marginalProfitlist lput (accessiblity - accessiblity_no_newlink - newedgecost) marginalProfitlist
               set nodelist lput m nodelist
             ]
          
           ask link id m [die]
          ]
            
           
         set m  m + 1   
        ]     
        
        if[marginalProfitlist] of location id != [] and [nodelist] of location id  != []
        [
        
          let node1 0
          
          if [max marginalProfitlist]  of location id > 0
          [
             ask location id   [
                 let maxvalue (max marginalProfitlist)
                 set p (position maxvalue marginalProfitlist) 
                 set node1 item p nodelist
                 create-link-with location node1 [set color black] ]
             
          ]
          
        ] 
        
        
      set i i + 1   
      
      
      tick 
      
        
   ]     
       
end



to find-networkpath-lengths [m]
  ;; initialize 
   let i 0
   let j 0
   let v 0
   let u 0
   let temp 0
   let newdist 0
   let node-count count locations
   ;output-show node-count
   set prev [] ;; the precedent of each node
   let index [] ; an index indicating whether each node has been added to the graph (true) or not added to the graph (falso)
   
   ;; initialization: set every distance to INFINITY until we discover a path 
   while [i < node-count]
   [
      ;;set distance-from-other-turtles lput (item i [distance-from-immediate-nodes] of location m) distance-from-other-turtles 
      ;; keep track of whether the node has been searched or not. 
      set index lput false index
      ;; if the distance infinity then put 0 as the initial value, otherwise put the distance
      ifelse item i [distance-from-other-turtles] of location m = infinity 
         [set prev lput 0 prev]
         [set prev lput m prev]
      set i i + 1
   ]   
 
   ;;output-show prev
      ;; distance for the source m to the source m is defined to be zero
   ;;set distance-from-other-turtles replace-item m distance-from-other-turtles 0 
   
   set index replace-item m index true  ;; having been searched

   ;; this loop corresponds to sending out the explorers walking the paths, where
   ;; the step of picking "the vertex, v, with the shorest path to s" corresponds
   ;; to an explorer arriving at an unexplored vertex
   set i 0
   while [i < node-count ]
   [
      ;;find the vertex v in set-of-nodes with smallest dist[] []
      
      set temp infinity 
      set u m 
      set j 0
      
      while [j < node-count]
      [ 
         if (item j index = false) and (item j [distance-from-other-turtles] of location m < temp )
         [ 
             set u j
             set temp (item j [distance-from-other-turtles] of location m)
         ]
         set j j + 1
      ]
      
      set index replace-item u index true
      
      set j 0
      
      while [ j < node-count]
      [  
          if  ( item j index = false ) and  (item j [distance-from-other-turtles] of location u < infinity)
          [
          
            ; ifelse [color] of location u = red or [color] of location j = red   
            ;     [ set newdist ( item u [distance-from-other-turtles] of location m + 2 * item j [distance-from-other-turtles] of location u ) ] 
            ;     [ set newdist ( item u [distance-from-other-turtles] of location m + item j [distance-from-other-turtles] of location u ) ] 
            
             set newdist ( item u [distance-from-other-turtles] of location m + item j [distance-from-other-turtles] of location u )    
             if newdist < item j [distance-from-other-turtles] of location m
             [
                ;;;
                ;;; update May 20, 2010
                ask location m [set distance-from-other-turtles replace-item j [distance-from-other-turtles] of location m newdist ]
               ; set [distance-from-other-turtles] of location m replace-item j [distance-from-other-turtles] of location m newdist
                set prev (replace-item j prev u)
             ]
          ]
         
          set j j + 1
      ]
      
      set i i + 1
    ]  
  
    ; output-show prev
    
    
   ;; calculate the profit of the whole network for location m
   set j 0
   let revenue 0
   ;let w_center 1500
   ask location m [

      while [j < node-count]
      [
         if item j distance-from-other-turtles < infinity and item j distance-from-other-turtles > 0 and j != m
         [
             
             ;;output-show "enter here"
             ;; revised on Dec. 14, 2011
             
             ifelse Scenario = "Single center"
             [ 
                ifelse  [xcor] of location j = 0 and [ycor] of location j  = 0    
                [ set revenue revenue +  w_center * (item j distance-from-other-turtles ) ^ (- delta)]
                [ set revenue revenue +  w * (item j distance-from-other-turtles) ^ (- delta) ]   
             ]
             [
                ifelse Scenario = "Two centers"
                [
                    ifelse ( [xcor] of location j = -1 * int(grid-size / 4) * scale  and [ycor] of location j = 0) or ( [xcor] of location j = int(grid-size / 4) * scale and [ycor] of location j = 0)
                    [ set revenue revenue +  w_center * (item j distance-from-other-turtles ) ^ (- delta)]
                    [ set revenue revenue +  w * (item j distance-from-other-turtles) ^ (- delta) ]   
    
                ]
                [
                    ifelse Scenario = "Four centers"
                    [ 
                       ifelse ([xcor] of location j = -1 * int(grid-size / 4) * scale and [ycor] of location j = 0) or ( [xcor] of location j =  int(grid-size / 4) * scale and [ycor] of location j = 0) 
                       or ([xcor] of location j = 0 and [ycor] of location j = -1 * int(grid-size / 4) * scale) or ([xcor] of location j  = 0 and [ycor] of location j = int(grid-size / 4) * scale)  
                       [ set revenue revenue +  w_center * (item j distance-from-other-turtles ) ^ (- delta)]
                       [ set revenue revenue +  w * (item j distance-from-other-turtles) ^ (- delta) ]  
  
                     ]
                     [
                       if Scenario =  "Nine centers"
                       [
                          ifelse ([xcor] of location j  = -1 * int(grid-size / 4) * scale and [ycor] of location j  = 0) or 
                            ([xcor] of location j  =  int(grid-size / 4) * scale and[ ycor] of location j  = 0) or
                            ([xcor] of location j  = 0 and [ycor] of location j  = -1 * int(grid-size / 4) * scale) or 
                            ([xcor] of location j  = 0 and [ycor] of location j  = int(grid-size / 4) * scale) or 
                            ([xcor] of location j = -1 * int(grid-size / 4) * scale and [ycor] of location j  = int(grid-size / 4) * scale) or 
                            ([xcor] of location j  =  int(grid-size / 4) * scale and [ycor] of location j  = int(grid-size / 4) * scale) or 
                            ( [xcor] of location j  = 0 and [ycor] of location j  = 0) or
                            ([xcor]  of location j =  int(grid-size / 4) * scale and [ycor]  of location j = int(grid-size / 4) * scale) or 
                            ([xcor] of location j =  int(grid-size / 4) * scale and [ycor] of location j = -1 * int(grid-size / 4) * scale) or 
                            ([xcor]  of location j  =  -1 * int(grid-size / 4) * scale and [ycor] of location j = -1 * int(grid-size / 4) * scale)
                            [ set revenue revenue +  w_center * (item j distance-from-other-turtles ) ^ (- delta)]
                            [ set revenue revenue +  w * (item j distance-from-other-turtles) ^ (- delta) ]  
                       ]
                     ]
                 ]
             ]       
           ]

               set j j + 1
         ]    
   
      set accessiblity revenue
      
    ]
end


to do-plot
  set-current-plot "Total segments"
  plot count links
end
  

to change-environment
  
  set background "environment2.jpg"
  ;; loads an image as a background from the current directory the model was launched from
  if Scenario = "Minneapolis skway"
  [ import-drawing background
    ask buildings [set color red set size 0.5]
  ]
end
  
  

to clear-environment
  
  ;; loads an image as a background from the current directory the model was launched from
   clear-drawing
   
   ;ask buildings [set color red set size 0.5]
   
  if Scenario = "Minneapolis skway"
  [ ask buildings [set color red set size 0.5] ]
   
end  

@#$#@#$#@
GRAPHICS-WINDOW
463
10
1013
581
22
22
12.0
1
10
1
1
1
0
1
1
1
-22
22
-22
22
1
1
1
ticks

CHOOSER
42
44
248
89
Scenario
Scenario
"Single center" "Two centers" "Four centers" "Nine centers" "Minneapolis skway"
4

BUTTON
273
54
444
87
Setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

SLIDER
38
201
245
234
Grid-size
Grid-size
5
15
7
2
1
NIL
HORIZONTAL

SLIDER
38
244
244
277
Scale
Scale
1
4
4
0.5
1
NIL
HORIZONTAL

SLIDER
41
121
246
154
delta
delta
0
3.0
0.52
0.01
1
NIL
HORIZONTAL

SLIDER
37
541
246
574
unitbenefit_p
unitbenefit_p
1
100
49
1
1
NIL
HORIZONTAL

SLIDER
38
493
246
526
unitedgecost
unitedgecost
10
150
90
10
1
NIL
HORIZONTAL

TEXTBOX
967
79
1117
97
NIL
11
0.0
1

SLIDER
38
295
243
328
newedgecost
newedgecost
0
200
65
5
1
NIL
HORIZONTAL

SLIDER
35
348
244
381
w_center
w_center
0
400
200
1
1
NIL
HORIZONTAL

SLIDER
35
398
243
431
w
w
0
400
107
1
1
NIL
HORIZONTAL

BUTTON
547
593
719
626
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

TEXTBOX
25
20
175
38
Scenario setting
11
0.0
1

TEXTBOX
22
102
172
120
Distance decay parameter
11
0.0
1

TEXTBOX
17
459
167
477
Skyway network parameters
11
0.0
1

TEXTBOX
19
172
169
190
Grid-like city parameters
11
0.0
1

PLOT
1074
67
1274
217
Total segments
Rounds
Segments
0.0
5.0
0.0
100.0
true
false
PENS
"default" 1.5 0 -2674135 true

TEXTBOX
1229
27
1379
45
System outputs
11
0.0
1

BUTTON
36
592
246
625
Change background
change-environment
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

BUTTON
750
593
917
626
Step by step
Go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

BUTTON
37
646
245
681
Clear background
clear-environment
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

TEXTBOX
272
602
422
630
Add the google view
11
0.0
1

TEXTBOX
274
657
424
675
Remove the goodgle view
11
0.0
1

@#$#@#$#@
WHAT IS IT?
-----------
This section could give a general understanding of what the model is trying to show or explain.


HOW IT WORKS
------------
This section could explain what rules the agents use to create the overall behavior of the model.


HOW TO USE IT
-------------
This section could explain how to use the model, including a description of each of the items in the interface tab.


THINGS TO NOTICE
----------------
This section could give some ideas of things for the user to notice while running the model.


THINGS TO TRY
-------------
This section could give some ideas of things for the user to try to do (move sliders, switches, etc.) with the model.


EXTENDING THE MODEL
-------------------
This section could give some ideas of things to add or change in the procedures tab to make the model more complicated, detailed, accurate, etc.


NETLOGO FEATURES
----------------
This section could point out any especially interesting or unusual features of NetLogo that the model makes use of, particularly in the Procedures tab.  It might also point out places where workarounds were needed because of missing features.


RELATED MODELS
--------------
This section could give the names of models in the NetLogo Models Library or elsewhere which are of related interest.


CREDITS AND REFERENCES
----------------------
This section could contain a reference to the model's URL on the web if it has one, as well as any other necessary credits or references.
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
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

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

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 4.1.3
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 1.0 0.0
0.0 1 1.0 0.0
0.2 0 1.0 0.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
