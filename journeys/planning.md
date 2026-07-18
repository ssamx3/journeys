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
 
 
 
 Passes:
 Commuter PASS: basically your streak. Not tiered
 RailPASS: Shows you how much youve put into each rail line with tiers.

 Things to consider:
 Need a way to procedurally generate fake place names
 Need a way to create logo word art from the subjects (or maybe include a mini logo maker)
 Need a way to make 3d ticket cheaply
 
 
 
 UI: 
 
 Main ui -> opens to a map. you are a node in the centre of the map, and there are four other "nodes" around you. each node is joined to the centre node by a connector, a bit like the tube map. the connectors shouldnt all be straight lines, and some should have little curves and turns in them (but obviously not so much that it would derail the train). This is all generated procedurally when the app is opened Below the map, there is also a size-changing sheet, which contains all the other features (a bit like find my or flighty or waze or apple maps) (not entirely sure how to do this one JUST yet so should research). on the ipad and mac, the sheet shouldnt come up from the bottom, but instead be on the side in its already expanded state. not sure if this is a native feature. 
 Clicking on a node will highlight the connector between the central node and the node selected, and bring up the journey planning flow in the sheet. the steps of this are 
 1. Show the central node location -> Selected node location with some text like "your journey" and then a big button at the bottom of the sheet to say "next". the sheet is currently in its smallest state
 2. Allow you to pick a train operator, still in the smallest state, big next button again. clicking a train operator changes the connector colour to the accent colour of the operator.
 3. Nice tactile lines slider to pick focus time, sliding behind 0 of the slider puts it in infinite (stopwwatch) mode  OR maybe a toggle i havent decided. still smallest, next button 
 4. sheet expands to MEDIUM size with a fluid springy animation showing the 3d ticket with all the details filled in and a GO button at the bottom. If the user chose indefinite, the destination field on the card shows --- 
 5. Enters the timer/stopwatch view.
 
Timer view -> 
The Selected route becomes a progress bar, the time left and stats are displayed in a small-medium version of the sheet at the bottom. there is also a cancel button available if you expand the sheet. 
Stopwatch view -> 
first thirty minutes is the selected route, but after that the map recentres and the 1st destination node becomes the central node, and a random new node is added to the route. we keep repeating this but every ten minutes now as the "stops" system. The sheet has the count up time and stats whatnot the big red "disembark" button. When this is clicked, the node currently travelling to becomes the final node, and an additional countdown until arrival at that node appears.

When finished -> The sheet shows you your stats from that journey and progress towards your railpass tier, then expands and shows you the ticket to let you rip the stub off, then if it was your stamp session you can also stamp your stamper card. Then goes back to the home screen with the destination just travelled to as the central node. 

In the sheet, there should be a way to pin things to the bottom (eg a big button)
In the sheet, when on the main map view and not in a session, you can expand it to see your previous stubs, your stubbook and your streak. it looks like a homescreen of widgets almost




Ui redesign: 
Two options:
Singular main page - 
The top section has a place to get tickets from. It shows the location you are currently at, and then theres a selector to choose the next location you want to go to (or randomise) and then a GET TICKETS -> button which takes you to the ticket flow (which will remain largely the same as prior but just without all the nodes stuff and sheet)
There is then a scrolling departures board which shows previous journeys / suggested ones, has a dot font for fun to make it look like departures board but it is just a Hstack you can scroll vertically with rounded rectangle cards that have destinations and times and operators on it 
A HStack {} of your cards/passes (you can horizontally scroll through them), tapping on  one will bring up its respective view with more detailed information about it 
A big stand out card that looks like a passport cover almost that allows you to open your stub book and look through your previous journeys.

Tabbed view - 
Basically the same but instead there is a departures tab and a Passes tab seperating the departures screen from the Cards and Stubbook
OR 3 tabs 
tab 1 - departures
tab 2 - passes
tab 3 - stubs (stubs has more detail, filters and a search feature), exposes this all on one click of the tab bar rather than having to go to the stubbook directly

However i question how much people will use pages 2 and 3 and if they truly need seperate tabs 
 
 */


