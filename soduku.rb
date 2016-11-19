module Soduku
  
  
  class Puzzle
    def initialize(lines)
      #TODO: respond to array
      soduku_string = lines.dup
      
      #strip whitespace characters
      soduku_string.gsub!(/\s/, "")
      
      #check size
      raise Invalid, "The grid has the wrong size" unless soduku_string.size == 81
      
      #^ = not
      if i = soduku_string.index(/[^123456789\.]/)
        raise Invalid, "Illegal character '#{soduku_string[i,1]}' found at position #{i}"
      end
      
      #replace . with 0
      soduku_string.gsub!(/\./, "0")
          
      #map to ints
      @grid = soduku_string.chars.map { |char| char.to_i }
      
      raise Invalid, "Puzzle has duplicates" if has_duplicates?
    end
    
    def to_s
      (0..8).collect {|row| puts @grid[row * 9, 9].map{|num| num.to_s}.join("|")}.compact
    end
    
    # make a duplicate of the array for us to work on
    def dup
      copy = super
      @grid = @grid.dup
      copy
    end
    
    # getter and setter for an array
    def [](row, col)
      #convert row values by * by 9
      @grid[row * 9 + col]
    end
    
    def []=(row, col, newvalue)
      unless (0..9).include?(newvalue)
        raise Invalid, "#{newvalue} is not a valid value"
      end
      @grid[row * 9 + col] = newvalue
    end
    
    #BoxOfIndex gives us index for the 9 boxes, starting in top left corner with box0, box1, box2 and so on
    BoxOfIndex = [
      0, 0, 0, 1, 1, 1, 2, 2, 2, 
      0, 0, 0, 1, 1, 1, 2, 2, 2, 
      0, 0, 0, 1, 1, 1, 2, 2, 2, 
      3, 3, 3, 4, 4, 4, 5, 5, 5,
      3, 3, 3, 4, 4, 4, 5, 5, 5,
      3, 3, 3, 4, 4, 4, 5, 5, 5,
      6, 6, 6, 7, 7, 7, 8, 8, 8,
      6, 6, 6, 7, 7, 7, 8, 8, 8,
      6, 6, 6, 7, 7, 7, 8, 8, 8
    ].freeze
    
    # finds all unknown (not solved) values, for each of those execute the passed block, giving it 
    # row, col, box as parameters
    def each_unknown
      0.upto 8 do | row |
        0.upto 8 do | col |
          index = row * 9 + col
          next if @grid[index] != 0
          box = BoxOfIndex[index]
          yield row, col, box
        end 
      end 
    end
    
    def has_duplicates?
      # uniq! returns nil if all the elements in an array are unique.
      # So if uniq! returns something then the board has duplicates.
      0.upto(8) { |row| return true if rowdigits(row).uniq!}
      0.upto(8) { |col| return true if coldigits(col).uniq!}
      0.upto(8) { |box| return true if boxdigits(box).uniq!}
      
      false
    end
    
    # all valid values 
    AllDigits = [1, 2, 3, 4, 5, 6, 7, 8, 9].freeze
    
    def possible(row, col, box)
      AllDigits - (rowdigits(row) + coldigits(col) + boxdigits(box))
    end
    
    private

    def rowdigits(row)
      # Extract the subarray that represents the row and remove all zeros.
      # Array subtraction is set difference, with duplicate removal.
      #subarray starting a row * 9 and then 9 values from there
      #remove 0
      @grid[row * 9, 9] - [0]
    end
    
    def coldigits(col)
      result = []
      col.step(80, 9) { |i| 
        val = @grid[i]
        if val != 0
          result << val
        end
      }
      result
    end
    
    BoxStartIndex = [0, 3, 6, 27, 30, 33, 54, 57, 60].freeze
    
    def boxdigits(box)
      i = BoxStartIndex[box]
      [
        @grid[i], @grid[i + 1], @grid[i + 2],
        @grid[i + 9], @grid[i + 10], @grid[i + 11],
        @grid[i + 18], @grid[i + 19], @grid[i + 20]
      ] - [0]
    end
  end
  
  #Exceptions
  class Invalid < StandardError
  end
  
  class Impossible < StandardError
  end
  
  def Soduku.scan(puzzle)
    unchanged = false #loop variable
    
    until unchanged
      unchanged = true
      rmin, cmin, pmin = nil
      min = 10
      
      #for each unknown do 
      puzzle.each_unknown do | row, col, box |
        #find possible candidates
        possible = puzzle.possible(row, col, box)
        case possible.size
          # 3 interesting values here:
          # 0 means that the puzzle can not be solved
          # 1 means that we have match, so update
          # more than one, see if it is the candidate with the fewest values
        when 0
          raise Impossible
        when 1
          puzzle[row, col] = possible[0]
          unchanged = false #we've made a change so we can go again
        else
          if unchanged && possible.size < min
            min = possible.size
            rmin, cmin, pmin = row, col, possible
          end
        end
      end
    end
    
    #return the cell with the smallest number of possibilities
    return rmin, cmin, pmin
  end
  
  def Soduku.solve(puzzle)
    #make a copy for us to work on
    puzzle = puzzle.dup
    
    c, r, p = scan(puzzle)
    
    return puzzle if c == nil

    p.each do |guess|
      puzzle[c, r] = guess
      begin
        return solve(puzzle)
      rescue Impossible
        next
      end
    end
  end
  
end

#puzzle = Soduku::Puzzle.new(".1...9.356.75.......84.36.1.61.8.......2..16.3.5.96.248.......6.2486..5..5.3.72.9")
puzzle = Soduku::Puzzle.new("46.85...2279.1.8...81...............91..3...........94...645.2...238..61...7...5.")
result = Soduku.solve(puzzle)
puts result.to_s
#puzzle.each_unknown { |row, col, box| print "Possible values for #{row}, #{col}, #{box} = #{puzzle.possible(row, col, box)} | "}