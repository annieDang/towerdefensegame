require 'rubygems'
require 'gosu'
require 'json'
require './circle'
require './find_path'
require './enums'

WIDTH, HEIGHT = 1000, 600
SIDE_WIDTH = 200
TILE_OFFSET = 30

def load_settings
    file = File.read('./settings.json')
    JSON.parse(file)
end

SETTING = load_settings



class Fortress 
    attr_accessor :name, :x, :y, :money, :wave, :height, :width, :level, :health
    def initialize(name, x, y, width, height)
        @name = name
        @x = x
        @y = y
        @width = width
        @height = height
        @level = 1
        setting = SETTING["level"][@level.to_s]
        @health = setting["health"]
        @money = setting["money"]
        @wave = SETTING["wave"][setting["wave"]]
    end
end

class Obstacle
    attr_accessor :obstacle_type, :x, :y, :image, :name
    def initialize(obstacle_type, x, y)
        @obstacle_type = obstacle_type
        @x = x
        @y = y
        if obstacle_type != Obstacle_type::Tower && obstacle_type != Obstacle_type::Empty
            setting = SETTING["obstacle"][@obstacle_type.to_s]
            @image = Gosu::Image.new(setting["image"])
            @name = setting["name"]
        end
    end
end

class Tower < Obstacle
    attr_accessor :obstacle_type, :x, :y, :image, :level, :name, :cost, :sell_price, :upgrage_price, :damage, :type, :range, :cooldown, :status
    
    def initialize(type, x, y)
        super(Obstacle_type::Tower, x, y)

        @type = type;
        @status = Tower_status::Building
        setting = SETTING["tower"][@type.to_s]
        @level = 1
        @image = Gosu::Image.new(setting["level#{@level}"]["image"])
        @range = setting["level#{@level}"]["range"]
    end

end

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
                fortress.health -= @damage
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



# Map class holds and draws tiles and gems.
class GameMap
    attr_accessor :width, :height, :tiles, :side_width
end

def setup_game_map
    game_map = GameMap.new
    game_map.width = (WIDTH - SIDE_WIDTH * 2)/TILE_OFFSET
    game_map.height = HEIGHT/TILE_OFFSET

    game_map.tiles = Array.new(game_map.width) do |x|
        Array.new(game_map.height) do |y|
            case rand(game_map.height)%23
            when 0
                Obstacle.new(Obstacle_type::Mountain, x, y)
            when 1
                Obstacle.new(Obstacle_type::Tree, x, y)
            when 2
                Obstacle.new(Obstacle_type::House, x, y)
            else
                Obstacle.new(Obstacle_type::Empty, x, y)
            end
        end
      end
      game_map
end

# attacking point 
def add_Hq(fortress, game_map)
    for x in (fortress.x)..(fortress.x + fortress.width - 1)
        for y in (fortress.y)..(fortress.y + fortress.height - 1)
            game_map.tiles[x][y] = Obstacle.new(Obstacle_type::HQ, x, y)
        end
    end
end

# spawning point
def add_infected_land(land, game_map)
    game_map.tiles[land.x][land.y] = Obstacle.new(Obstacle_type::Infected_forest, land.x, land.y)
end

# Detects if a 'mouse sensitive' area has been clicked on

def area_clicked(leftX, topY, rightX, bottomY)
    # complete this code
    if ((mouse_x > leftX and mouse_x < rightX) and (mouse_y > topY and mouse_y < bottomY))
      true
    else
      false
    end
end

class Roamers < (Example rescue Gosu::Window)
    def initialize
        super WIDTH, HEIGHT

        self.caption = "Roamers"
        @ground = Gosu::Image.new("media/ground.jpeg")
        @circle = Gosu::Image.new("media/circle.png")

        # generate a random map full with obstacles 
        # and then add hq, infected land
        @game_map = setup_game_map 
        puts "Map is generated width #{@game_map.width} heigh #{@game_map.height}"
        @fortress = Fortress.new("Happy Place", 2, 17, 2, 2)
        @infected_land = Obstacle.new(Obstacle_type::Infected_forest, 16, 2)
        add_Hq @fortress,@game_map
        add_infected_land @infected_land,@game_map

        # get shortest path 
        @path = shortest_path(@game_map, @infected_land, @fortress)

        @creeps = Array.new

        @picked_tower_type = Tower_type::Range
        
        start_game
      
    end

    def start_game
        @start_health = @fortress.health

        @song = Gosu::Song.new("media/sound/background_normal.mp3") 
        @song.volume = 0.2
        @song.play(true)

        @game_status = Game_status::Running
    end

    def draw
        # background
        @ground.draw(0, 0, ZOrder::BACKGROUND, (WIDTH * 1.0) /@ground.width,  (HEIGHT * 1.0) /@ground.height)
        
        # draw obstacles (tree, mountains, houses), fortress and infected area
        draw_game_map(@game_map)
        
        # draw creeps
        @creeps.each { |creep| creep.spawn }

        # draw ui
        draw_ui

        # show tower indicator
        dragging_tower

        # game status
        draw_game_status
    end

    def draw_game_status
        case @game_status
        when Game_status::Game_over
            @status_font.draw("<c=00008b>GAME OVER!!!</c>", WIDTH/2 - 40, HEIGHT/2 - 5, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::RED)
        end
    end


    def draw_ui
        @ui_offset = 5
        
        @group_font = Gosu::Font.new(20)
        @status_font = Gosu::Font.new(25)
        @button_font = Gosu::Font.new(13)
        @item_name_font = Gosu::Font.new(15)
        @info_font = Gosu::Font.new(13)
        
        draw_left_menu
        draw_right_menu
    end

    def draw_left_menu
        draw_rect(@ui_offset, @ui_offset, SIDE_WIDTH - 2*@ui_offset, HEIGHT - 2*@ui_offset, Gosu::Color.argb(0xff_585858))
        @group_font.draw("<b><c=00008b>STORE</c></b>", 65, 30, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::BLACK)
        # draw_tower_list
    end

    def draw_right_menu
        draw_rect(WIDTH - SIDE_WIDTH + @ui_offset, @ui_offset, WIDTH - @ui_offset, HEIGHT - 2*@ui_offset, Gosu::Color.argb(0xff_585858))
        
        draw_line(WIDTH - SIDE_WIDTH + @ui_offset, HEIGHT/3, Gosu::Color::BLACK, WIDTH - @ui_offset, HEIGHT/3, Gosu::Color::BLACK, ZOrder::PLAYER, mode=:default)
        @group_font.draw("<b><u><c=00008b>#{@fortress.name}</c></u></b>", WIDTH - SIDE_WIDTH + 35, 30, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::BLACK)
        @info_font.draw("<b><c=00008b>Health: #{@fortress.health}</c></b>", WIDTH - SIDE_WIDTH + 50, 80, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::BLACK)
        @info_font.draw("<b><c=00008b>Money: #{@fortress.money}</c></b>", WIDTH - SIDE_WIDTH + 50, 100, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::BLACK)
        @info_font.draw("<b><c=00008b>Level: #{@fortress.level}</c></b>", WIDTH - SIDE_WIDTH + 50, 120, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::BLACK)
        
        draw_button (WIDTH - SIDE_WIDTH + 20), 150, 70, 30, "Start"
        draw_button (WIDTH - SIDE_WIDTH + 110), 150, 70, 30, "Reset"
    end

    def draw_button x, y, width, heigh, label
        draw_rect(x, y, width, heigh, Gosu::Color::BLUE)
        @button_font.draw("<b><c=00008b>#{label}</c></b>", x + 20, y + 10, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::BLACK)
    end

    def grid_area_clicked
        @game_map.width.times do |x|
            @game_map.height.times do |y|
                leftX = x * TILE_OFFSET + SIDE_WIDTH
                topY = y * TILE_OFFSET
                rightX = leftX + TILE_OFFSET
                bottomY = topY + TILE_OFFSET
                if area_clicked(leftX, topY, rightX, bottomY)
                    return [x, y]
                end
            end
        end
        nil
    end

    def dragging_tower
        grid = grid_area_clicked
        if !@picked_tower_type.nil? and grid
            x, y = grid
            obstacle = @game_map.tiles[x][y]
            if obstacle.obstacle_type == Obstacle_type::Empty
                setting = SETTING["tower"][@picked_tower_type.to_s]
                @image = Gosu::Image.new(setting["level1"]["image"])
                start_x = x * TILE_OFFSET + SIDE_WIDTH
                start_y = y * TILE_OFFSET
                @image.draw(start_x, start_y, ZOrder::UI, (TILE_OFFSET * 1.0) /@image.width,  (TILE_OFFSET * 1.0) /@image.height)
                radius =  setting["level1"]["range"].to_f
                @circle.draw(start_x + TILE_OFFSET/2- radius/2, start_y + TILE_OFFSET/2 - radius/2, ZOrder::UI,  radius/@circle.width,  radius/@circle.width)
            else
                draw_x x, y if obstacle.obstacle_type != Obstacle_type::Tower and obstacle.obstacle_type != Obstacle_type::HQ
            end
        end
    end

    def draw_x x, y
        leftX = x * TILE_OFFSET + SIDE_WIDTH
        topY = y * TILE_OFFSET
        rightX = leftX + TILE_OFFSET
        bottomY = topY + TILE_OFFSET
        thickness = 4
        color =  Gosu::Color::RED
        draw_quad(leftX - thickness/2, topY, color, leftX + thickness/2, topY, color, rightX - thickness/2, bottomY, color, rightX + thickness/2, bottomY, color)
        draw_quad(leftX + TILE_OFFSET - thickness/2, topY, color, leftX + TILE_OFFSET + thickness/2, topY, color, rightX - TILE_OFFSET - thickness/2, bottomY, color, rightX - TILE_OFFSET + thickness/2, bottomY, color)
    end

    def draw_game_map(game_map)
        draw_grid(game_map)
        # Very primitive drawing function:
        # Draws all the tiles, some off-screen, some on-screen.
        drawedHQ = false
        game_map.width.times do |x|
            game_map.height.times do |y|
                tile = game_map.tiles[x][y]
                if tile.obstacle_type != Obstacle_type::Empty
                    start_x = x * TILE_OFFSET + SIDE_WIDTH
                    start_y = y * TILE_OFFSET
                    case tile.obstacle_type 
                    when Obstacle_type::HQ
                        tile.image.draw(start_x, start_y, ZOrder::BACKGROUND, (TILE_OFFSET * @fortress.width * 1.0) /tile.image.width,  (TILE_OFFSET * @fortress.height * 1.0) /tile.image.height) if !drawedHQ
                        drawedHQ = true
                    when Obstacle_type::Tower
                        tile.image.draw(start_x, start_y, ZOrder::BACKGROUND, (TILE_OFFSET * 1.0) /tile.image.width,  (TILE_OFFSET * 1.0) /tile.image.height)
                        tile.status = Tower_status::Built 
                    else
                        tile.image.draw(start_x, start_y, ZOrder::BACKGROUND, (TILE_OFFSET * 1.0) /tile.image.width,  (TILE_OFFSET * 1.0) /tile.image.height)
                    end
                    
                end
            end
        end
    end

    def draw_grid(game_map)
        color = Gosu::Color.argb(0xff_808080)
        for x in 0..game_map.width do
            draw_line(x * TILE_OFFSET + SIDE_WIDTH, 0 , color,  x * TILE_OFFSET + SIDE_WIDTH, HEIGHT, color, ZOrder::BACKGROUND, mode=:default)
        end
        
        for y in 0..game_map.height do
            draw_line(SIDE_WIDTH, y * TILE_OFFSET, color,  WIDTH - SIDE_WIDTH, y * TILE_OFFSET, color, ZOrder::BACKGROUND, mode=:default)
        end
    end

    def collision
    end

    def sprawn_creep
        @last_sprawn_time = Gosu.milliseconds
        zombies = @fortress.wave["zombie"]
        sum = zombies.inject(0){|sum,x| sum + x["count"].to_i }
        random_no = rand(sum)
        x = SIDE_WIDTH + @infected_land.x * TILE_OFFSET
        y = @infected_land.y * TILE_OFFSET
        zombies.each do |zombie|
            return Creep.new(zombie["type"], x, y, @path) if ((random_no -= zombie["count"]) < 0)
        end
    end

    def update
        return if @game_status == Game_status::Game_over

        if @fortress.health > 0 
            @creeps.each { |creep| creep.move @fortress}
            @creeps.reject! {|creep| creep.dead }
            @creeps << sprawn_creep if(Gosu.milliseconds - (@last_sprawn_time || 0) > 1000)
        else
            @game_status = Game_status::Game_over
        end
    end

    def needs_cursor?; true; end

    def button_down(id)
		case id
	    when Gosu::MsLeft
            grid = grid_area_clicked
            if !@picked_tower_type.nil? and grid
                radius =  100.0
                x, y = grid
                if @game_map.tiles[x][y].obstacle_type == Obstacle_type::Empty
                    @game_map.tiles[x][y] = Tower.new(@picked_tower_type, x, y)
                end 
            end
	    end
	end
end


Roamers.new.show if __FILE__ == $0