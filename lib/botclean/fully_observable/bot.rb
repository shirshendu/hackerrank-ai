#!/usr/bin/ruby

# Head ends here
def next_move posx, posy, board

  puts "Best path:"
  best_path = Botclean::FullyObservable::Bot.find_path posx, posy, 5, 5, board
  puts best_path.steps
  puts best_path.steps.count
  puts "================="
  Botclean::FullyObservable::Bot.next_move
end
class Object
  def deep_clone
    return @deep_cloning_obj if @deep_cloning
    @deep_cloning_obj = clone
    @deep_cloning_obj.instance_variables.each do |var|
      val = @deep_cloning_obj.instance_variable_get(var)
      begin
        @deep_cloning = true
        val = val.deep_clone
      rescue TypeError
        next
      ensure
        @deep_cloning = false
      end
      @deep_cloning_obj.instance_variable_set(var, val)
    end
    deep_cloning_obj = @deep_cloning_obj
    @deep_cloning_obj = nil
    deep_cloning_obj
  end
end

class Array
  def deep_clone
    a=[]
    each {|x| a << x.deep_clone }
    a
  end
end

module Botclean
  module FullyObservable
    module Bot
      class << self
        def find_path posx, posy, sizx, sizy, board
          # Where am I?
          @board = board
          @robot = Position.new([posx,posy])

          initial_state = State.new posx, posy, sizx, sizy, board

          StateSpaceGraph.find_best_path initial_state
        end

        def next_move posx, posy, sizx, sizy, board
          # Where am I?
          @board = board
          @robot = Position.new([posx,posy])

          state = State.new posx, posy, sizx, sizy, board
          #Lets decide on a path
          path = Path.new [state],[]

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
      attr_accessor :board,:robot_pos
      def initialize px,py,sizx,sizy,board
        @robot_pos = Position.new [px,py]
        @max_rows = sizy
        @max_cols = sizx
        @board = board
      end

      def == state
        state.robot_pos == @robot_pos and state.board == @board
      end

      def final?
        @board.each do |line|
          return false if line.index("d")
        end
        return true
      end

      def allowed_actions
        actions = []
        actions << "CLEAN" if @board[@robot_pos.r][@robot_pos.c] == "d"
        actions << "LEFT" if @robot_pos.c > 0
        actions << "RIGHT" if @robot_pos.c < 4
        actions << "UP" if @robot_pos.r > 0
        actions << "DOWN" if @robot_pos.r < 4
        actions.reject { |action|
          test_state = self.deep_clone
          test_state.take_action action
          !StateSpaceGraph.uniq? test_state
        }
        actions
      end

      def take_action action
        #return unless allowed_actions.index(action)

        if action == "CLEAN"
          @board[@robot_pos.r][@robot_pos.c] = "b"
          return
        end
        # The square its leaving behind
        @board[@robot_pos.r][@robot_pos.c] = @board[@robot_pos.r][@robot_pos.c] == "d" ? "d" : "-"
        if action == "LEFT"
          # The square its entering
          @board[@robot_pos.r][@robot_pos.c - 1] = @board[@robot_pos.r][@robot_pos.c - 1] == "d" ? "d" : "b"
          # The updated position
          @robot_pos.c -= 1
        elsif action == "RIGHT"
          # The square its entering
          @board[@robot_pos.r][@robot_pos.c + 1] = @board[@robot_pos.r][@robot_pos.c + 1] == "d" ? "d" : "b"
          # The updated position
          @robot_pos.c += 1
        elsif action == "UP"
          # The square its entering
          @board[@robot_pos.r - 1][@robot_pos.c] = @board[@robot_pos.r - 1][@robot_pos.c] == "d" ? "d" : "b"
          # The updated position
          @robot_pos.r -= 1
        elsif action == "DOWN"
          # The square its entering
          @board[@robot_pos.r + 1][@robot_pos.c] = @board[@robot_pos.r + 1][@robot_pos.c] == "d" ? "d" : "b"
          # The updated position
          @robot_pos.r += 1
        end
      end
    end

    class Path
      attr_accessor :states, :steps
      def initialize states,steps
        @states = states
        @steps = steps
      end
      
      def << step
        @states << @states.last.deep_clone
        @states.last.take_action step
        @steps << step
      end

      def include? test_state
        @states.each do |state|
          return true if state == test_state
        end
        return false
      end
    end

    module StateSpaceGraph
      class << self
        attr_accessor :initial_state,:paths
        def find_best_path state
          @paths = []
          @initial_state = state
          iterate_paths
        end

        def iterate_paths
          if @paths.empty?
            @paths << Path.new([@initial_state], [])
          end

          new_paths = []
          @paths.each do |path|
            return path if path.states.last.final?
            last_state = path.states.last
            path.states.last.allowed_actions.each do |action|
              new_paths << path.deep_clone
              new_paths.last << action
            end
          end
          @paths = new_paths
          optimize_paths
          iterate_paths
        end

        def optimize_paths
          last_states = @paths.map {|path| path.states.last}
          paths_to_delete = []
          paths_to_keep = []
          last_states.each.with_index do |test_state,state_index|
            @paths.each.with_index do |path,path_index|
              if state_index != path_index and path.include? test_state and path.steps.count <= @paths[state_index].steps.count
                paths_to_delete << state_index
                paths_to_keep << path_index
              end
            end
          end
                binding.pry
          paths_to_delete.uniq!
          @paths = @paths.reject.with_index {|path,i| paths_to_delete.include? i }
          #paths_to_delete.each do |i|
          #  @paths.delete_at i
          #end
        end

        def uniq? state
          @paths.each do |path|
            return false if path.include? state
          end
          return true
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
