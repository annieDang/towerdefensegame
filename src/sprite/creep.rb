class Creep
    attr_accessor :type, :x, :y, :name, :damage, :speed, :profit, :health, :size, :die, :path, :grid_x, :grid_y, :mapping_map, :image_tiles
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
        @full_health = zombie_setting["health"]

        # characteristic
        @size = zombie_setting["size"]
        @x,@y = cal_pos

        @exploxed_image = Gosu::Image.new("./media/boom.png")
        @blood_image_tiles = Gosu::Image.load_tiles("./media/blood.png", 472, 428)

        load_tiles(zombie_setting)
        
        @path = path
        @mapping_map = mapping_map
        @moves = @path.dup
        @game_map = nil

        @current_tile_indx = 0
        @current_move = nil
        @exploded = false
        @exploded_time = nil
        @die = false
        @died_time = nil

        @next_tile_x, @next_tile_y = next_tile(@moves.shift)
        
    end

    def load_tiles(zombie_setting)
        tiles = Gosu::Image.load_tiles(zombie_setting["image_tile_dir"], 32, 32)
        tile_no = zombie_setting["tile_loc"]
        
        start = (tile_no - 1) * 3

        @image_tiles = Array.new
        for x in 0..3 do
            for y in 0..2 do
                @image_tiles << tiles[start + y]
            end
            start +=12
        end 
    end

    def cal_pos
        x = SIDE_WIDTH + @grid_x * TILE_OFFSET + TILE_OFFSET/2 - @size/2
        y = @grid_y * TILE_OFFSET + TILE_OFFSET/2 - @size/2
        [x,y]
    end

    def cal_last_grid
        cal_grid(@back_to_last_move, @grid_x, @grid_y)
    end

    def self.cal_grid move, last_x, last_y
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

    def walking_toward?
        return Direction::Down if (@current_tile_indx >= 0 and @current_tile_indx <= 2)
        return Direction::Up if (@current_tile_indx >= 9 and @current_tile_indx <= 11)
        return Direction::Left if (@current_tile_indx >= 3 and @current_tile_indx <= 5)
        return Direction::Right if (@current_tile_indx >= 6 and @current_tile_indx <= 8)
    end

    def next_tile move
        next_tile_x, next_tile_y  = [@x, @y]
        
        last_move = walking_toward?
        case move
        when Direction::Up
            next_tile_y = @y - TILE_OFFSET
            @current_tile_indx = 9 if (last_move != Direction::Up)
        when Direction::Down
            next_tile_y = @y + TILE_OFFSET
            @current_tile_indx = 0 if (last_move != Direction::Down)
        when Direction::Left
            next_tile_x = @x - TILE_OFFSET
            @current_tile_indx = 3 if (last_move != Direction::Left)
        when Direction::Right
            next_tile_x = @x + TILE_OFFSET
            @current_tile_indx = 6 if (last_move != Direction::Right)
        end
        @grid_x, @grid_y =  Creep.cal_grid(move, @grid_x, @grid_y)
        @current_move = move
        [next_tile_x, next_tile_y]
    end

    def next_tile_img
        next_tile_img = @current_tile_indx + 1
        case @current_move
        when Direction::Up
            next_tile_img = 9 if next_tile_img > 11
        when Direction::Down
            next_tile_img = 0 if next_tile_img > 2
        when Direction::Left
            next_tile_img = 3 if next_tile_img > 5
        when Direction::Right
            next_tile_img = 6 if next_tile_img > 8
        end
        @current_tile_indx = next_tile_img
    end

    def move fortress
        return if die?
        return if exploded?
        # if @game_map
        #     return if @game_map.tiles[@grid_x][@grid_y].obstacle_type == Obstacle_type::Tower
        # end
        @x += (@next_tile_x - @x).abs > @speed - 1 ? @speed : 1 if @next_tile_x > @x
        @x -= (@next_tile_x - @x).abs > @speed - 1 ? @speed : 1 if @next_tile_x < @x
        @y += (@next_tile_y - @y).abs > @speed - 1 ? @speed : 1 if @next_tile_y > @y
        @y -= (@next_tile_y - @y).abs > @speed - 1 ? @speed : 1 if @next_tile_y < @y
        next_tile_img()
        if [@x, @y] == [@next_tile_x,@next_tile_y]
            next_move = @moves.shift
            # attack the fortress
            if next_move.nil?
                fortress.health = fortress.health - @damage < 0? 0 : fortress.health - @damage
                explode!
            else
                @next_tile_x, @next_tile_y = next_tile(next_move)
            end
        end
    end

    def update_game_map new_game_map
        @game_map = new_game_map
    end

    def spawn
        if(die? and !bury?)
            tile_indx = (Gosu.milliseconds - @died_time.to_i)/(1000/@blood_image_tiles.length) - 1
            tile_img = @blood_image_tiles[tile_indx]
            tile_img.draw(@x, @y, 4, (TILE_OFFSET * 1.0)/tile_img.width, (TILE_OFFSET * 1.0)/tile_img.height)
            return
        end
        if(exploded? and !exploded_done?)
            ratio = (Gosu.milliseconds - @exploded_time.to_i)/2000.0
            @exploxed_image.draw(@x, @y, ZOrder::PLAYER, ratio, ratio)
            return
        end

        @image_tiles[@current_tile_indx].draw(@x - @size/2, @y - @size/2, ZOrder::PLAYER)
        $window.draw_rect(@x- @size/2 , @y - @size/2, @size,2, Gosu::Color::BLACK, ZOrder::BACKGROUND)
        draw_health_bar(@health, @full_health, @x - @size/2, @y - @size/2, @image_tiles[@current_tile_indx].width ,2)
    end

    # Removes the creep from its list
    def kill!
        @die = true
        @died_time = Gosu.milliseconds if !@died_time
    end

    # Checks whether this sprite should be deleted
    def die?
        @die
    end

    def bury?
        die? and (Gosu.milliseconds - @died_time > 500)
    end

    def explode!
        @exploded = true
        @exploded_time = Gosu.milliseconds if !@exploded_time
    end
    # Checks whether this sprite should be deleted
    def exploded?
        @exploded
    end

    def exploded_done?
        exploded? and (Gosu.milliseconds - @exploded_time > 500)
    end
    
end