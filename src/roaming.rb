require 'rubygems'
require 'gosu'
require 'json'
require_relative 'find_path'
require_relative 'setting'

require_relative 'sprite/creep'
require_relative 'sprite/circle'

require_relative 'object/obstacle'
require_relative 'object/fortress'
require_relative 'object/tower'

WIDTH, HEIGHT = 1000, 600
SIDE_WIDTH = 200
TILE_OFFSET = 30

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
        @deco = Gosu::Image.new("media/fun.jpeg")

        # generate a random map full with obstacles 
        # and then add hq, infected land
        @game_map = setup_game_map 
        puts "Map is generated width #{@game_map.width} heigh #{@game_map.height}"
        @fortress = Fortress.new("LAST FORTRESS", 2, 17, 2, 2)
        @infected_land = Obstacle.new(Obstacle_type::Infected_forest, 16, 2)
        add_Hq @fortress,@game_map
        add_infected_land @infected_land,@game_map

        # get shortest path 
        @path = shortest_path(@game_map, @infected_land, @fortress)

        @creeps = Array.new

        @picked_tower_type = Tower_type::Range
        @picked_tower_level = 1
        @picked_tower = nil
        
        start_game
      
    end

    def start_game
        @start_health = @fortress.health

        @song = Gosu::Song.new("media/sound/background_normal.mp3") 
        @song.volume = 0.2
        # @song.play(true)

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
            @status_font.draw("GAME OVER!!!", WIDTH/2 - 40, HEIGHT/2 - 5, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::WHITE)
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
        draw_rect(@ui_offset, @ui_offset, SIDE_WIDTH - 2*@ui_offset, HEIGHT - 2*@ui_offset, Gosu::Color::WHITE)
        @group_font.draw("<b><c=00008b>STORE</c></b>", 65, 50, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::BLACK)
        draw_line(20, 80, Gosu::Color::BLACK, SIDE_WIDTH - 20, 80, Gosu::Color::BLACK, ZOrder::PLAYER, mode=:default)

        # draw_tower_list
        start_at = 100
        SETTING["level"][@fortress.level.to_s]["towers"].each do |tower_type|
            tower_setting = SETTING["tower"][tower_type.to_s]
            @image = Gosu::Image.new(tower_setting["level1"]["image"])
            draw_button(20, start_at, 150, 30, tower_setting["name"])
            @image.draw(120, start_at, ZOrder::UI, (TILE_OFFSET * 1.0) /@image.width,  (TILE_OFFSET * 1.0) /@image.height)
            start_at += 50
        end

        @group_font.draw("<b><c=00008b>INFORMATION</c></b>", 35, 320, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::BLACK)
        draw_line(20, 345, Gosu::Color::BLACK, SIDE_WIDTH - 20, 345, Gosu::Color::BLACK, ZOrder::PLAYER, mode=:default)
        
        if @picked_tower
            draw_tower_info @picked_tower.type, @picked_tower.level
            draw_button(10, 500, 80, 30, "Upgrade")
            draw_button(110, 500, 80, 30, "Sell")
        else
            if @picked_tower_type
                draw_tower_info @picked_tower_type, @picked_tower_level
            end
        end
    end

    def draw_tower_info picked_tower_type, picked_tower_level
        setting = SETTING["tower"][picked_tower_type.to_s]
        @info_font.draw("Tower name: #{setting["name"]}", 20, 380, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::BLACK)
        detail_setting = setting["level#{picked_tower_level}"]
        @info_font.draw("Range: #{detail_setting["range"]}", 20, 400, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::BLACK)
        @info_font.draw("Damage: #{detail_setting["damage"]}", 20, 420, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::BLACK)
        @info_font.draw("Price: #{detail_setting["price"]}", 20, 440, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::BLACK)
        @info_font.draw("Cool down time: #{detail_setting["cool_down"]}", 20, 460, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::BLACK)
    end

    def draw_right_menu
        draw_rect(WIDTH - SIDE_WIDTH + @ui_offset, @ui_offset, WIDTH - @ui_offset, HEIGHT - 2*@ui_offset, Gosu::Color::WHITE)
        
        # draw_line(WIDTH - SIDE_WIDTH + @ui_offset, HEIGHT/3, Gosu::Color::BLACK, WIDTH - @ui_offset, HEIGHT/3, Gosu::Color::BLACK, ZOrder::PLAYER, mode=:default)
        @group_font.draw("<b><u><c=00008b>#{@fortress.name}</c></u></b>", WIDTH - SIDE_WIDTH + 25, 50, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::BLACK)
        draw_line(WIDTH - SIDE_WIDTH + 20, 80, Gosu::Color::BLACK, WIDTH - 20, 80, Gosu::Color::BLACK, ZOrder::PLAYER, mode=:default)
        
        @info_font.draw("<b><c=00008b>Health: #{@fortress.health}</c></b>", WIDTH - SIDE_WIDTH + 50, 100, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::BLACK)
        @info_font.draw("<b><c=00008b>Money: #{@fortress.money}</c></b>", WIDTH - SIDE_WIDTH + 50, 120, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::BLACK)
        @info_font.draw("<b><c=00008b>Level: #{@fortress.level}</c></b>", WIDTH - SIDE_WIDTH + 50, 140, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::BLACK)
        
        
        draw_button((WIDTH - SIDE_WIDTH + 20), 180, 70, 30, "Start")
        draw_button((WIDTH - SIDE_WIDTH + 110), 180, 70, 30, "Reset")

        deco_width = 1.0 * (SIDE_WIDTH - @ui_offset)
        deco_height = 1.0 * (HEIGHT - 250)
        @deco.draw(WIDTH - SIDE_WIDTH + @ui_offset, 250, ZOrder::UI,  deco_width/@deco.width,  deco_height/@deco.height)
    end

    def draw_button x, y, width, height, label
        color = Gosu::Color::GRAY
        color = Gosu::Color::BLUE if area_clicked(x, y, x + width, y + height)
        draw_rect(x, y, width, height, color)
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
        zombies.each do |zombie|
            return Creep.new(zombie["type"], @infected_land.x, @infected_land.y, @game_map, @path) if ((random_no -= zombie["count"]) < 0)
        end
    end

    def update
        return if @game_status == Game_status::Game_over

        if @fortress.health > 0 
            @creeps.each { |creep| creep.move @fortress}
            @creeps.reject! {|creep| creep.dead }
            if(@creeps.length < 10)
                @creeps << sprawn_creep if(Gosu.milliseconds - (@last_sprawn_time || 0) > 1000)
            end
        else
            @game_status = Game_status::Game_over
        end
    end

    def needs_cursor?; true; end
 
    def tower_buttons_rect()
        start_at = 100
        SETTING["level"][@fortress.level.to_s]["towers"].each do |tower_type|
            if(area_clicked(20, start_at, 170, start_at + 30))
                @picked_tower_type = tower_type
                @picked_tower_level = 1
                break
            end
            start_at += 50
        end
    end

    def reset
        if area_clicked((WIDTH - SIDE_WIDTH + 110), 180, WIDTH - SIDE_WIDTH + 110 + 70, 180 + 30)
            @creeps =[]
            @game_map.width.times do |x|
                @game_map.height.times do |y|
                    tile = @game_map.tiles[x][y]
                    if tile.obstacle_type == Obstacle_type::Tower
                        @game_map.tiles[x][y] = Obstacle.new(Obstacle_type::Empty, x, y)
                    end
                end
            end 
        end
    end

    def button_down(id)
		case id
	    when Gosu::MsLeft
            grid = grid_area_clicked
            if grid
                x, y = grid
                tile = @game_map.tiles[x][y]
                case tile.obstacle_type
                when Obstacle_type::Empty
                    if !@picked_tower_type.nil?
                        @game_map.tiles[x][y] = Tower.new(@picked_tower_type, x, y)
                        @creeps.each { |creep| creep.change_tile(@game_map.tiles[x][y], @game_map, @fortress) }
                        @path = shortest_path(@game_map, @infected_land, @fortress)
                    end
                when Obstacle_type::Tower
                    @picked_tower = tile
                end
            end

            # tower picking
            tower_buttons_rect

            reset
	    end
	end
end


window = Roamers.new
window.show
