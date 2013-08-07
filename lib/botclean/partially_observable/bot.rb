#!/usr/bin/ruby

# Head ends here
def next_move posx, posy, board
  Botclean::PartiallyObservable::Bot.next_move posx, posy, board
end

module Botclean
  module PartiallyObservable
    module Bot
      class << self
        attr_accessor :explored
        def next_move posx, posy, board
          # Where am I?
          @board = board
          @robot = Position.new([posx,posy])
          update_explored
          # Look at all this dirt under my feet!
          if (board[posy][posx] == "d")
            "CLEAN"
          else
            # Off we go, to dirtier pastures.
            way = @robot.way_towards(closest("d"))
            return way if way

            way = @robot.way_towards(closest("o"))

          end
        end
        def update_explored
          f=File.new "explored" if File.exists? "explored"
          if !f
            @explored ||= ["ooooo","ooooo","ooooo","ooooo","ooooo"]
          else
            @explored = f.each_line.map {|l| l.strip}
          end
          r_start = @robot.r - 1 >= 0 ? @robot.r - 1 : 0
          c_start = @robot.c - 1 >= 0 ? @robot.c - 1 : 0
          r_end = @robot.r + 1 <= 4 ? @robot.r + 1 : 4
          c_end = @robot.c + 1 <= 4 ? @robot.c + 1 : 4
          (r_start..r_end).each do |r|
            (c_start..c_end).each do |c|
              @explored[r][c] = @board[r][c]
            end
          end
          f.close if f
          fw = File.new "explored", "w"
          fw.puts @explored
          fw.close
          #binding.pry
        end

        def closest(destination_type)
          (1..8).each_with_index do |offset|
            r_start = ((@robot.r - offset) >= 0) ? @robot.r - offset : 0
            r_end = ((@robot.r + offset) <= 4) ? @robot.r + offset : 4
            c_start = ((@robot.c - offset) >= 0) ? @robot.c - offset : 0
            c_end = ((@robot.c + offset) <= 4) ? @robot.c + offset : 4
            (r_start..r_end).each_with_index do |row|
              (c_start..c_end).each_with_index do |col|
                if @explored[row][col] == destination_type and (@robot.c - col).abs + (@robot.r - row).abs == offset
                  p = Position.new([col,row])
                  return p
                end
              end
            end
          end
          return nil
        end
      end
    end
  end
end

class Position
  attr_accessor :r,:c

  def initialize(pos)
    @r = pos[1]
    @c = pos[0]
  end

  def way_towards(p)
    return nil unless p
    if p.c != self.c
      return "LEFT" if p.c < self.c
      return "RIGHT" if p.c > self.c
    else
      return "UP" if p.r < self.r
      return "DOWN" if p.r > self.r
    end
  end
end
# Tail starts here
#pos = gets.split.map {|i| i.to_i}
#board = Array.new(5)
#
#(0...5).each do |i|
#  board[i] = gets.strip
#end
#
#puts next_move pos[0], pos[1], board
