require './lib/botclean/partially_observable/bot.rb'
require './lib/botclean/partially_observable/environment.rb'
require 'pry'
#Environment.data = "0 0
#b---d
#-d--d
#--dd-
#--d--
#----d"
module Botclean::PartiallyObservable
Environment.data = "0 0
b----
-d---
---d-
---d-
--d-d"
File.unlink "explored" if File.exists? "explored"
count = 0
until Environment.fully_clean? or count == 51 do
  action = Bot.next_move(Environment.robot_pos.c, Environment.robot_pos.r, Environment.visible_board)
  Environment.robot_action(action)
  puts action
  count += 1
end
if count <=50
  puts "Cleaning successful"
  puts "Total moves: #{count}"
else
  puts "Cleaning failure"
end
end
