#!/usr/bin/ruby

# Head ends here
def next_move posx, posy, sizx, sizy, board
  if File.exists? "solution"
    steps = read_solution
    action = steps.shift
    persist_solution steps
    return action
  else
    best_path = Botclean::FullyObservable::Bot.find_path posx, posy, sizx, sizy, board
    steps = best_path.steps
    action = steps.shift
    persist_solution steps
    return action
  end
end

def persist_solution step_array
  #binding.pry
  f=File.new "solution","w"
  f.write Marshal.dump(step_array)
  f.close
end

def read_solution
  f=File.new "solution"
  steps = Marshal.restore f.read
  f.close
  steps
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

          initial_state_data = "#{posx} #{posy}\n#{sizx} #{sizy}\n#{board.join("\n")}".to_sym
          initial_state = State.new initial_state_data

          StateSpaceGraph.find_best_path initial_state
        end
      end
    end

    class State
      attr_accessor :data
      def initialize init_data
        @data = init_data.to_sym
      end

      def deep_clone
        State.new @data
      end

      def == state
        state.data == @data
      end

      def robot_pos
        @robot_pos || 
          begin
            @robot_pos = Position.new @data.to_s.lines.first.strip.split.map!{|i| i.to_i}
          end
      end

      def robot_pos= position
        @robot_pos = position
        @data = "#{position.c} #{position.r}\n#{sizx} #{sizy}\n#{board.join("\n")}".to_sym
      end
      
      def board
        @board ||
          begin
            lines = @data.to_s.lines.to_a
            lines.shift
            lines.shift
            lines.map! {|l| l.strip}
            @board = lines
          end
      end

      def board= new_board
        @board = new_board
        @data = "#{position.c} #{position.r}\n#{sizx} #{sizy}\n#{new_board.join("\n")}".to_sym
      end

      def sizx
        @sizx ||
          begin
            lines = @data.to_s.lines.to_a
            lines.shift
            siz = lines.shift.strip.split.map!{|i| i.to_i}
            @sizy = siz[1]
            @sizx = siz[0]
          end
      end
      
      def sizy
        @sizy ||
          begin
            lines = @data.to_s.lines.to_a
            lines.shift
            siz = lines.shift.strip.split.map!{|i| i.to_i}
            @sizx = siz[0]
            @sizy = siz[1]
          end
      end

      def final?
        !@data.to_s.index("d")
      end

      def allowed_actions
        actions = []
        actions << "CLEAN" if board[robot_pos.r][robot_pos.c] == "d"
        actions << "LEFT" if robot_pos.c > 0
        actions << "RIGHT" if robot_pos.c < (sizx - 1)
        actions << "UP" if robot_pos.r > 0
        actions << "DOWN" if robot_pos.r < (sizy - 1)
        actions
      end

      def take_action action
        #return unless allowed_actions.index(action)
        board
        robot_pos
        if action == "CLEAN"
          @board[robot_pos.r][robot_pos.c] = "b"
          update_data
          return
        end
        # The square its leaving behind
        @board[robot_pos.r][robot_pos.c] = board[robot_pos.r][robot_pos.c] == "d" ? "d" : "-"
        if action == "LEFT"
          # The square its entering
          @board[robot_pos.r][robot_pos.c - 1] = board[robot_pos.r][robot_pos.c - 1] == "d" ? "d" : "b"
          # The updated position
          @robot_pos.c -= 1
        elsif action == "RIGHT"
          # The square its entering
          @board[robot_pos.r][robot_pos.c + 1] = board[robot_pos.r][robot_pos.c + 1] == "d" ? "d" : "b"
          # The updated position
          @robot_pos.c += 1
        elsif action == "UP"
          # The square its entering
          @board[robot_pos.r - 1][robot_pos.c] = board[robot_pos.r - 1][robot_pos.c] == "d" ? "d" : "b"
          # The updated position
          @robot_pos.r -= 1
        elsif action == "DOWN"
          # The square its entering
          @board[robot_pos.r + 1][robot_pos.c] = board[robot_pos.r + 1][robot_pos.c] == "d" ? "d" : "b"
          # The updated position
          @robot_pos.r += 1
        end
        update_data
      end
      
      def update_data
        @data = "#{robot_pos.c} #{robot_pos.r}\n#{sizx} #{sizy}\n#{board.join("\n")}".to_sym
      end
    end

    class Path
      attr_accessor :states
      def initialize states
        @states = states
      end

      def steps
        @states.values[0...-1]
      end

      def << step
        last_state_data = @states.keys.last
        new_state = State.new(last_state_data)
        new_state.take_action step
        raise ArgumentError if @states.has_key? new_state.data # Should eliminate returns and loops
        @states[last_state_data] = step
        @states[new_state.data] = nil
      end

      def include? test_state
        @states.has_key? test_state.data
      end
    end

    module StateSpaceGraph
      class << self
        attr_accessor :initial_state,:paths
        def find_best_path state
          @paths = []
          @initial_state = state
          @states = {}
          iterate_paths
        end

        def iterate_paths
          if @paths.empty?
            @paths << Path.new({@initial_state.data => nil})
          end

          new_paths = []
          @paths.count.times do
            path = @paths.shift
            last_state = State.new(path.states.keys.last)
            return path if last_state.final?
            last_state.allowed_actions.each do |action|
              test_state = last_state.deep_clone
              test_state.take_action action
              next unless StateSpaceGraph.uniq? test_state

              # Since this state is unique,
              @states[test_state.data] = nil

              @paths << path.deep_clone
              begin
                @paths.last << action
              rescue ArgumentError
                @paths.pop
              end
            end
          end

          #binding.pry
          #optimize_paths
          iterate_paths
        end

        def uniq? state
          !@states.has_key? state.data
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
