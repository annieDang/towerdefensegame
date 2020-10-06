class Creep
    attr_accessor :type, :x, :y, :name, :damage, :speed, :profit, :health, :image, :radius, :dead, :path
    def initialize(type, x, y, path)
        @type = type;
        @x = x
        @y = y
        # load the setting
        zombie_setting =  SETTING["zombies"][type.to_s]
        @name = zombie_setting["name"]
        @speed = zombie_setting["speed"]
        @damage = zombie_setting["damage"]
        @profit = zombie_setting["profit"]
        @health = zombie_setting["health"]

        # characteristic
        @radius = zombie_setting["radius"]
        @image = Gosu::Image.new(Circle.new(@radius/2))
        @color = zombie_setting["color"]
        @path = path
        @moves = @path.dup
        @next_tile_x, @next_tile_y = next_tile(@moves.shift)
        @dead = false
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
        when Direction::Down
            next_tile_y = @y + TILE_OFFSET
        when Direction::Left
            next_tile_x = @x - TILE_OFFSET
        when Direction::Right
            next_tile_x = @x + TILE_OFFSET
        end
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
        @image.draw(@x + TILE_OFFSET/2 - @radius/2, @y + TILE_OFFSET/2 - @radius/2, ZOrder::PLAYER, 1, 1, color)
    end
end
