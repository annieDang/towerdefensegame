class Creep
    attr_accessor :type, :x, :y, :name, :damage, :speed, :profit, :health, :image, :radius, :dead, :path, :grid_x, :grid_y, :mapping_map
    def initialize(type, grid_x, grid_y, path, mapping_map)
        @type = type;
        @grid_x = grid_x
        @grid_y = grid_y
        # load the setting
        zombie_setting =  SETTING["zombies"][type.to_s]
        @name = zombie_setting["name"]
        @speed = zombie_setting["speed"]
        @damage = zombie_setting["damage"]
        @profit = zombie_setting["profit"]
        @health = zombie_setting["health"]

        # characteristic
        @radius = zombie_setting["radius"]
        @x,@y = cal_pos

        @image = Gosu::Image.new(Circle.new(@radius/2))
        @color = zombie_setting["color"]
        
        @path = path
        @mapping_map = mapping_map
        @moves = @path.dup
        
        @next_tile_x, @next_tile_y = next_tile(@moves.shift)
        @back_to_last_move = @path[0]
        @dead = false

    end

    def cal_pos
        x = SIDE_WIDTH + @grid_x * TILE_OFFSET + TILE_OFFSET/2 - @radius/2
        y = @grid_y * TILE_OFFSET + TILE_OFFSET/2 - @radius/2
        [x,y]
    end

    def cal_last_grid
        cal_grid(@back_to_last_move, @grid_x, @grid_y)
    end

    def cal_grid move, last_x, last_y
        x = last_x
        y = last_y
        case move
        when Direction::Up
            y = last_y - 1
        when Direction::Down
            y = last_y + 1
        when Direction::Left
            x = last_x - 1
        when Direction::Right
            x = last_x + 1
        end
        [x,y]
    end

    # is location one step in the move?
    def cal_step loc_x, loc_y
        length = -1
        x = @grid_x
        y = @grid_y
        remain_step = @moves.dup
        puts "tile_loc #{loc_x},#{loc_y}"
        puts "path length : #{@path.length}"
        puts "remain_step_lenght : #{remain_step.length}"
        next_move = remain_step.shift
        while !next_move.nil? do
            return length if(loc_x ==x and loc_y == y)
               
            x, y = cal_grid(next_move, x, y)
            next_move = remain_step.shift
            length +=1
        end
        length
    end

    # when game_map gets updated 
    def update_game_map tile, new_game_map, fortress
        location_tile = cal_step(tile.x, tile.y)
        
        puts "location_tile : #{location_tile}"
        # found it
        if location_tile > -1
            creep_tile = new_game_map.tiles[grid_x][grid_y]
            if location_tile <= 1
                last_move_x, last_move_y = cal_last_grid()
                creep_tile = new_game_map.tiles[last_move_x][last_move_y]
            end
                
            new_path = shortest_path(creep_tile, fortress)
            change_path(new_path)
        end
    end

    def change_path new_path
        @moves = new_path.dup
    end

    def next_tile move
        next_tile_x, next_tile_y  = [@x, @y]
        case move
        when Direction::Up
            next_tile_y = @y - TILE_OFFSET
            @back_to_last_move = Direction::Down
        when Direction::Down
            next_tile_y = @y + TILE_OFFSET
            @back_to_last_move = Direction::Up
        when Direction::Left
            next_tile_x = @x - TILE_OFFSET
            @back_to_last_move = Direction::Right
        when Direction::Right
            next_tile_x = @x + TILE_OFFSET
            @back_to_last_move = Direction::Left
        end
        @grid_x, @grid_y =  cal_grid(move, @grid_x, @grid_y)
        [next_tile_x, next_tile_y]
    end

    def move fortress
        return if @dead
        @x += (@next_tile_x - @x).abs > @speed - 1 ? @speed : 1 if @next_tile_x > @x
        @x -= (@next_tile_x - @x).abs > @speed - 1 ? @speed : 1 if @next_tile_x < @x
        @y += (@next_tile_y - @y).abs > @speed - 1 ? @speed : 1 if @next_tile_y > @y
        @y -= (@next_tile_y - @y).abs > @speed - 1 ? @speed : 1 if @next_tile_y < @y
        if [@x, @y] == [@next_tile_x,@next_tile_y]
            next_move = @moves.shift
            # attack the fortress
            if next_move.nil?
                fortress.health = fortress.health - @damage < 0? 0 : fortress.health - @damage
                @dead = true
            else
                @next_tile_x, @next_tile_y = next_tile(next_move)
            end
        end
    end

    def spawn
        color = Gosu::Color::BLACK
        case @color
        when "gray"
            color = Gosu::Color::GRAY
        when "yellow"
            color = Gosu::Color::YELLOW
        end
        @image.draw(@x, @y, ZOrder::PLAYER, 1, 1, color)
    end
end
