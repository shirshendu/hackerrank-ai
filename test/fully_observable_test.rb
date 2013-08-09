require './lib/botclean/fully_observable/environment.rb'
require './lib/botclean/fully_observable/bot.rb'
require 'pry'
#Environment.data = "0 0
#b---d
#-d--d
#--dd-
#--d--
#----d"
Botclean::FullyObservable::Environment.data = "0 0
bd--d
-d---
---d-
---d-
d-d--"
#binding.pry
  puts "Best path:"
  best_path = Botclean::FullyObservable::Bot.find_path 0, 0, 5, 5, Botclean::FullyObservable::Environment.board
  puts best_path.steps
  puts best_path.steps.count
  puts "================="
count = 0
until Botclean::FullyObservable::Environment.fully_clean? or count == 51 do
  action = Botclean::FullyObservable::Bot.next_move(Botclean::FullyObservable::Environment.robot_pos.c, Botclean::FullyObservable::Environment.robot_pos.r, 5, 5, Botclean::FullyObservable::Environment.board)
  Botclean::FullyObservable::Environment.robot_action(action)
  puts action
  count += 1
end
if count <=50
  puts "Cleaning successful"
  puts "Total moves: #{count}"
else
  puts "Cleaning failure"
end
