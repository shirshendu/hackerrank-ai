module Botclean::PartiallyObservable::Environment
  class << self
    attr_accessor :board,:robot_pos,:visibility

    def fully_clean?
      @board.each do |row|
        return false if row.index("d")
        return false if row.index("o")
      end
      return true
    end

    def robot_action(action)
      if action == "CLEAN"
        clean(@robot_pos)
        return
      end
      # The square its leaving behind
      @board[@robot_pos.r][@robot_pos.c] = @board[@robot_pos.r][@robot_pos.c] == "d" ? "d" : "-"
      if action == "LEFT" and @robot_pos.c - 1 >= 0
        # The square its entering
        @board[@robot_pos.r][@robot_pos.c - 1] = @board[@robot_pos.r][@robot_pos.c - 1] == "d" ? "d" : "b"
        # The updated position
        @robot_pos.c -= 1
      elsif action == "RIGHT" and @robot_pos.c + 1 <= 4
        # The square its entering
        @board[@robot_pos.r][@robot_pos.c + 1] = @board[@robot_pos.r][@robot_pos.c + 1] == "d" ? "d" : "b"
        # The updated position
        @robot_pos.c += 1
      elsif action == "UP" and @robot_pos.r - 1 >= 0
        # The square its entering
        @board[@robot_pos.r - 1][@robot_pos.c] = @board[@robot_pos.r - 1][@robot_pos.c] == "d" ? "d" : "b"
        # The updated position
        @robot_pos.r -= 1
      elsif action == "DOWN" and @robot_pos.r + 1 <= 4
        # The square its entering
        @board[@robot_pos.r + 1][@robot_pos.c] = @board[@robot_pos.r + 1][@robot_pos.c] == "d" ? "d" : "b"
        # The updated position
        @robot_pos.r += 1
      end
      update_visibility
    end

    def clean(position)
      @board[position.r][position.c] = "b"
    end

    def data=(input)
      line = input.lines[0].strip
      @robot_pos = Position.new(line.split.map {|i| i.to_i})
      @board = Array.new(5)

      (1...6).each do |i|
        @board[i - 1] = input.lines[i].strip
      end

      update_visibility
    end

    def data
      data_str = "#{@robot_pos.c} #{@robot_pos.r}"
      visible_board.each_with_index do |line,i|
        data_str += "\n#{line}"
      end
      data_str
    end

    def visible_board
      @board.map.with_index do |line,i|
        visline = line.chars.map.with_index do |char,j|
          if @visibility[i][j] == "1"
            char
          else
            "o"
          end
        end
        visline.join ""
      end
    end

    def update_visibility
      @visibility = ["00000","00000","00000","00000","00000"]
      r_start = @robot_pos.r - 1 >= 0 ? @robot_pos.r - 1 : 0
      c_start = @robot_pos.c - 1 >= 0 ? @robot_pos.c - 1 : 0
      r_end = @robot_pos.r + 1 <= 4 ? @robot_pos.r + 1 : 4
      c_end = @robot_pos.c + 1 <= 4 ? @robot_pos.c + 1 : 4
      (r_start..r_end).each do |r|
        (c_start..c_end).each do |c|
          @visibility[r][c] = "1"
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
      if p.c != self.c
        return "LEFT" if p.c < self.c
        return "RIGHT" if p.c > self.c
      else
        return "UP" if p.r < self.r
        return "DOWN" if p.r > self.r
      end
    end
  end
end


