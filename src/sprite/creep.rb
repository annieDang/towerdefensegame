class Creep
    attr_accessor :type, :x, :y, :name, :damage, :speed, :profit, :health, :image, :radius, :dead, :path, :grid_x, :grid_y, :mapping_map
    def initialize(type, grid_x, grid_y, game_map, path, mapping_map)
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

    def cal_all_steps
        steps = Array[]
        x = @grid_x
        y = @grid_y
        moves = @path.dup
        next_move = moves.shift

        steps << [x, y]
        while !next_move.nil? do
            x,y = cal_grid(next_move, x, y)
            steps << [x, y]
            next_move = moves.shift
        end
        steps
    end

    def cal_step x, y, steps
        current_step = -1
        start = 0
        steps.each do |step|
            if (step[0] == x and step[1] == y)
                current_step = start
                break
            end
            start += 1
        end
        current_step
    end

    # add/remove
    def change_tile tile, game_map, fortress
        steps_to_hq = cal_all_steps
        affected_step = cal_step(tile.x, tile.y, steps_to_hq)
        creep_current_step = cal_step(@grid_x, @grid_y, steps_to_hq)
    
        # remove
        if affected_step > creep_current_step
            creep_tile = game_map.tiles[grid_x][grid_y]
            if affected_step - creep_current_step == 0
                last_move_x, last_move_y = cal_last_grid()
                creep_tile = game_map.tiles[last_move_x][last_move_y]
            end
                
            new_path = shortest_path(creep_tile, fortress)
            change_path(new_path)
        end
    end

    def change_path path
        @path = path
        @moves = @path.dup
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
