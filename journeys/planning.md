//
//  journeys.md
//  journeys
//
//  Created by sam on 12/07/2026.
//

/*
 Planning for journeys (app)
 
 
 Flow for starting a journey:
 Enter the app
 click where you would like to travel on the map (random destination names)
 choose time of journey (or indefinite if you want that)
 choose rail company (each company is a subject so you get miles for each company seperately)
 any bonuses introduced by your railpass are addded. can also use your commuter pass (obtained from starting a 3+ day streak, levels up at milestones 7, 30, 60, 120, 365, 2y, 3y, 4y etc..., maybe more milestones though). you must get at least 5 stamps a week to maintain your commuter pass (stamps are added at the end of each session (focus for minimum 20min to obtain a stamp)
 Print out your ticket and click GO
 Flow for injourney:
 InRailDisplay -> shows time spent or time left depending on timer or stopwatch mode picked
 shows your miles travelled
 shows a map with your destination for timer mode
 shows a map with stops every 10 minutes for indefinite mode -> you can choose where to disembark. choosing to disembark will cause the train to stop at the next station, and give you the rest of the time as overdrive which gives you a 1.5x miles bonus). indefinite mode will have no stops until 30 minutes to prevent abuse of overdrive.
 
 Flow for disembarking:
 Rip your ticket stub off (you add this to your collection)
 Get your commuter pass stamp
 return to the starting ui
 
 Additionally you can open your passbook and see your stubs (individual journeys) and check your total stats and railpass progress for each subject (after travelling a certain amount of miles on each line, you can level your pass up to silver, gold, platinum etc like a credit card)

 Things to consider:
 Need a way to procedurally generate fake place names
 Need a way to create logo word art from the subjects (or maybe include a mini logo maker)
 Need a way to make 3d ticket cheaply
 
 */


