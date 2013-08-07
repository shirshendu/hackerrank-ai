#!/usr/bin/ruby

# Head ends here
def next_move posx, posy, board
  Botclean::FullyObservable::Bot.next_move posx, posy, 5, 5, board
end

module Botclean
  module FullyObservable
    module Bot
      class << self
        def next_move posx, posy, sizx, sizy, board
          # Where am I?
          @board = board
          @robot = Position.new([posx,posy])

          #state = State.new posx, posy, sizx, sizy, board
          #Lets decide on a path
          #path = Path.new [state],[]

          # Look at all this dirt under my feet!
          if (board[posy][posx] == "d")
            "CLEAN"
          else
            # Off we go, to dirtier pastures.
            @robot.way_towards(closest("d"))
          end
        end

        def closest(destination_type)
          (1..8).each_with_index do |offset|
            r_start = ((@robot.r - offset) >= 0) ? @robot.r - offset : 0
            r_end = ((@robot.r + offset) <= 4) ? @robot.r + offset : 4
            c_start = ((@robot.c - offset) >= 0) ? @robot.c - offset : 0
            c_end = ((@robot.c + offset) <= 4) ? @robot.c + offset : 4
            (r_start..r_end).each_with_index do |row|
              (c_start..c_end).each_with_index do |col|
                if @board[row][col] == destination_type and (@robot.c - col).abs + (@robot.r - row).abs == offset
                  p = Position.new([col,row])
                  return p
                end
              end
            end
          end
        end
      end
    end

    class State
      attr_accessor :board
      def initialize px,py,sizx,sizy,board
        @robot_pos = Position.new [py,px]
        @max_rows = sizy
        @max_cols = sizx
        @board = board
      end

      def == state
        state.robot_pos == @robot_pos
        state.board == @board
      end

      def final?
        @board.each do |line|
          return false if line.index("d")
        end
        return true
      end
    end

    class Path
      def initialize states,steps
        @states = states
        @steps = steps
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

  def == pos
    pos and pos.r == @r and pos.c == @c
  end

  def way_towards(p)
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
