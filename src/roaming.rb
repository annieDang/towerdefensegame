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
require_relative 'button'

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
        @fortress = Fortress.new("LAST FORTRESS", 2, 17, Obstacle_type::HQ, 2, 2)
        @infected_land = Obstacle.new(Obstacle_type::Infected_forest, 16, 2)
        add_Hq(@fortress,@game_map)
        add_infected_land(@infected_land,@game_map)

        # cache
        @mapping_map = generate_mapping(@game_map, @infected_land, @fortress)
        
        # get shortest path 
        @path = shortest_path(@infected_land, @fortress)

        @creeps = Array.new

        @picked_tower_type = Tower_type::Range
        @picked_tower_level = 1
        @picked_tower = nil
        
        create_buttons
        
        start_game

        @notification = nil
        @notification_start_time = Gosu.milliseconds
    end

    def start_game
        @start_health = @fortress.health

        @song = Gosu::Song.new("media/sound/background_normal.mp3") 
        @song.volume = 0.2
        @song.play(true)

        @game_status = Game_status::Running

        @start_game = Gosu.milliseconds
        @time = 0
    end

    def create_buttons
        start_at =  100
        SETTING["level"][@fortress.level.to_s]["towers"].each do |tower_type|
            tower_setting = SETTING["tower"][tower_type.to_s]
            btn = Button.new(20, start_at, 150, 30, tower_setting["name"], "tower_#{tower_type}")
            btn.set_left_align
            start_at += 50
        end
        
        @upgrade_btn = Button.new(10, 540, 80, 30, "Upgrade", "upgrade")
        @sell_btn = Button.new(110, 540, 80, 30, "Sell", "sell")
        @upgrade_btn.set_hidden(true)
        @sell_btn.set_hidden(true)

        Button.new((WIDTH - SIDE_WIDTH + 20), 180, 70, 30, "Pause", "start")
        Button.new((WIDTH - SIDE_WIDTH + 110), 180, 70, 30, "Reset", "reset")

    end

    def make_notification info
        @notification = info
        @notification_start_time = Gosu.milliseconds
    end

    def draw
        # background
        @ground.draw(0, 0, ZOrder::BACKGROUND, (WIDTH * 1.0) /@ground.width,  (HEIGHT * 1.0) /@ground.height)
        
        # draw obstacles (tree, mountains, houses), fortress and infected area
        draw_game_map
        
        # draw creeps
        @creeps.each { |creep| creep.spawn }

        # draw ui
        draw_ui

        # show tower indicator
        dragging_tower

        # show collision
        collision

        # game status
        draw_status

        #draw_buttons
        Button.buttons.each { |button| draw_button(button) if !button.hidden }
        
    end

    def draw_game_status text
        height = @status_font.height
        width = @status_font.text_width(text, scale_x = 1)
        draw_rect(WIDTH/2 - width/2 - 50, HEIGHT/2 - height/2 - 10, width + 100, height + 20, Gosu::Color::GRAY)
        @status_font.draw(text, WIDTH/2 - width/2,  HEIGHT/2 - height/2, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::WHITE)
    end

    def draw_status
        case @game_status
        when Game_status::Game_over
            draw_game_status "GAME OVER!!!"
        when Game_status::Pause
            draw_game_status "PAUSED"
        when Game_status::Won
            draw_game_status "YOU WON!!!"
        end

        if @notification
            height = @status_font.height
            width = @status_font.text_width(@notification, scale_x = 1)
            draw_rect(WIDTH/2 - width/2 - 50, HEIGHT/2 - height/2 - 10, width + 100, height + 20, Gosu::Color::BLACK)
            @status_font.draw(@notification, WIDTH/2 - width/2,  HEIGHT/2 - height/2, ZOrder::BACKGROUND, 1.0, 1.0, Gosu::Color::WHITE)
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
            @image.draw(120, start_at, ZOrder::UI, (TILE_OFFSET * 1.0) /@image.width,  (TILE_OFFSET * 1.0) /@image.height)
            start_at += 50
        end

        @group_font.draw("<b><c=00008b>INFORMATION</c></b>", 35, 320, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::BLACK)
        draw_line(20, 345, Gosu::Color::BLACK, SIDE_WIDTH - 20, 345, Gosu::Color::BLACK, ZOrder::PLAYER, mode=:default)
        
        if @picked_tower
            draw_tower_info @picked_tower.type, @picked_tower.level
            
        else
            if @picked_tower_type
                draw_tower_info @picked_tower_type, @picked_tower_level
            end
        end
    end

    def draw_tower_info picked_tower_type, picked_tower_level
        setting = SETTING["tower"][picked_tower_type.to_s]
        
        image = Gosu::Image.new(setting["level#{picked_tower_level}"]["image"])
        image.draw(70, 370, ZOrder::BACKGROUND, (TILE_OFFSET * 1.0) /image.width,  (TILE_OFFSET * 1.0) /image.height)
        x = 40
        @info_font.draw("Tower name: #{setting["name"]}", x, 420, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::BLACK)
        detail_setting = setting["level#{picked_tower_level}"]
        @info_font.draw("Range: #{detail_setting["range"]}", x, 440, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::BLACK)
        @info_font.draw("Damage: #{detail_setting["damage"]}", x, 460, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::BLACK)
        @info_font.draw("Price: #{detail_setting["price"]}", x, 480, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::BLACK)
        @info_font.draw("Sell_price: #{detail_setting["price"]/2}", x, 500, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::BLACK)
        @info_font.draw("Cool down time: #{detail_setting["cool_down"]}", x, 520, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::BLACK)
    end

    def draw_right_menu
        draw_rect(WIDTH - SIDE_WIDTH + @ui_offset, @ui_offset, WIDTH - @ui_offset, HEIGHT - 2*@ui_offset, Gosu::Color::WHITE)
        
        @info_font.draw("<b><c=00008b>TIME: #{@time}</c></b>", WIDTH - SIDE_WIDTH + 70, 30, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::BLACK)
        # draw_line(WIDTH - SIDE_WIDTH + @ui_offset, HEIGHT/3, Gosu::Color::BLACK, WIDTH - @ui_offset, HEIGHT/3, Gosu::Color::BLACK, ZOrder::PLAYER, mode=:default)
        @group_font.draw("<b><u><c=00008b>#{@fortress.name}</c></u></b>", WIDTH - SIDE_WIDTH + 25, 50, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::BLACK)
        draw_line(WIDTH - SIDE_WIDTH + 20, 80, Gosu::Color::BLACK, WIDTH - 20, 80, Gosu::Color::BLACK, ZOrder::PLAYER, mode=:default)
        
        @info_font.draw("<b><c=00008b>Health: #{@fortress.health}</c></b>", WIDTH - SIDE_WIDTH + 50, 100, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::BLACK)
        @info_font.draw("<b><c=00008b>Money: #{@fortress.money}</c></b>", WIDTH - SIDE_WIDTH + 50, 120, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::BLACK)
        @info_font.draw("<b><c=00008b>Level: #{@fortress.level}</c></b>", WIDTH - SIDE_WIDTH + 50, 140, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::BLACK)
        
        start_lable = "Pause"
        if @game_status == Game_status::Pause
            start_lable = "Start"
        end

        deco_width = 1.0 * (SIDE_WIDTH - @ui_offset)
        deco_height = 1.0 * (HEIGHT - 250)
        @deco.draw(WIDTH - SIDE_WIDTH + @ui_offset, 250, ZOrder::UI,  deco_width/@deco.width,  deco_height/@deco.height)
    end

    def draw_button button 
        color = Gosu::Color::GRAY
        color = Gosu::Color::BLUE if area_clicked(button.x, button.y, button.x + button.width, button.y + button.height)
        draw_rect(button.x, button.y, button.width, button.height, color)
        
        width = @button_font.text_width(button.label, scale_x = 1)
        height = @button_font.height

        if button.left_align
            @button_font.draw(button.label, button.x + 20, button.y + (button.height - height)/2, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::BLACK)
        else
            @button_font.draw(button.label, button.x + (button.width - width)/2, button.y + (button.height - height)/2, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::BLACK)
        end
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

    def draw_game_map
        draw_grid
        # Very primitive drawing function:
        # Draws all the tiles, some off-screen, some on-screen.
        drawedHQ = false
        @game_map.width.times do |x|
            @game_map.height.times do |y|
                tile = @game_map.tiles[x][y]
                if tile.obstacle_type != Obstacle_type::Empty
                    next if (tile.obstacle_type == Obstacle_type::HQ and drawedHQ)
                    
                    if tile.obstacle_type == Obstacle_type::HQ
                        @fortress.draw
                        drawedHQ = true
                        next
                    end
                    
                    tile.draw
                end
            end
        end
    end

    def draw_grid
        color = Gosu::Color.argb(0xff_808080)
        for x in 0..@game_map.width do
            draw_line(x * TILE_OFFSET + SIDE_WIDTH, 0 , color,  x * TILE_OFFSET + SIDE_WIDTH, HEIGHT, color, ZOrder::BACKGROUND, mode=:default)
        end
        
        for y in 0..@game_map.height do
            draw_line(SIDE_WIDTH, y * TILE_OFFSET, color,  WIDTH - SIDE_WIDTH, y * TILE_OFFSET, color, ZOrder::BACKGROUND, mode=:default)
        end
    end

    def collision
        Tower.towers().each do |tower|
            @creeps.each do |creep|
                if tower.collision?(creep)
                    tower_x = tower.x * TILE_OFFSET + SIDE_WIDTH + TILE_OFFSET/2
                    tower_y = tower.y * TILE_OFFSET + TILE_OFFSET/2
                    draw_line(tower_x, tower_y, Gosu::Color::RED, creep.x, creep.y, Gosu::Color::RED, ZOrder::PLAYER, mode=:default)
                    creep.health -= tower.damage
                end
            end
        end
    end

    def sprawn_creep
        @last_sprawn_time = Gosu.milliseconds
        zombies = @fortress.wave["zombie"]
        sum = zombies.inject(0){|sum,x| sum + x["count"].to_i }
        random_no = rand(sum)
        zombies.each do |zombie|
            return Creep.new(zombie["type"], @infected_land.x, @infected_land.y, @path, @mapping_map) if ((random_no -= zombie["count"]) < 0)
        end
    end

    def update
        return if @game_status == Game_status::Game_over || @game_status == Game_status::Won
        
        if @game_status == Game_status::Next_level
            reset
            @fortress.next_level
            @game_status = Game_status::Running
        end

        if @fortress.level >3
            @game_status == Game_status::Won
            return
        end

        if @fortress.health < 0
            @game_status = Game_status::Game_over
            return 
        end

        @time = (Gosu.milliseconds - @start_game)/1000 if @game_status == Game_status::Running
        # 30 seconds/level
        if @time >= SETTING["time_per_level"]
            @notification = "Next level"
            @game_status == Game_status::Next_level
            return
        end
        
        if @game_status == Game_status::Running
            # move them
            @creeps.each { |creep| creep.move @fortress}
            
            # kill the died
            @creeps.each { |creep| @fortress.money += creep.profit if creep.health <0}
            @creeps.each { |creep| creep.dead = true if creep.health <0}

            # remove the died 
            @creeps.reject! {|creep| creep.dead }
            
            if(@creeps.length < @fortress.number_of_creeps)
                @creeps << sprawn_creep if(Gosu.milliseconds - (@last_sprawn_time || 0) > 1000)
            end
        end

        if (Gosu.milliseconds - @notification_start_time) > 1000
            @notification = nil
        end

    end

    def needs_cursor?; true; end

    def reset
        @start_game = Gosu.milliseconds
        @time = 0

        @creeps =[]
        @game_map.width.times do |x|
            @game_map.height.times do |y|
                tile = @game_map.tiles[x][y]
                if tile.obstacle_type == Obstacle_type::Tower
                    @game_map.tiles[x][y] = Obstacle.new(Obstacle_type::Empty, x, y)
                end
            end
        end 

        # reset player's data
        @fortress.load_setting

        # reset game status
        start_game

        # reset towers
        Tower.clear_towers
    end

    def start_pause
        case @game_status
        when Game_status::Pause
            @game_status = Game_status::Running
            @start_time = Gosu.milliseconds - @time * 1000
        when Game_status::Running
            @game_status = Game_status::Pause
        end
    end 

    def upgrade
        upgrade_price = @picked_tower.get_upgrade_price

        if upgrade_price == -1 
            make_notification("Cannot upgrade anymore!") 
            return
        end

        if @fortress.money < upgrade_price
            make_notification("Not enough money for upgrading!") 
            return
        end

        tower = @game_map.tiles[@picked_tower.x][@picked_tower.y]
        tower.upgrade
        @fortress.money -= @picked_tower.get_upgrade_price 
    end

    def sell
        @game_map.tiles[@picked_tower.x][@picked_tower.y] = Obstacle.new(Obstacle_type::Empty, @picked_tower.x, @picked_tower.y)
        Tower.towers.reject! {|tower| tower.x == @picked_tower.x  and tower.y == @picked_tower.y }
        @fortress.money += @picked_tower.sell_price

        reset_picked_tower
    end

    def is_button_clicked? 
        Button.buttons.each do |button|
            next if !area_clicked(button.x, button.y, button.x + button.width, button.y + button.height)
            case button.id
            when "start"
                start_pause
                button.label = "Pause" if (@game_status == Game_status::Running)
                button.label = "Start" if (@game_status == Game_status::Pause)
            when "reset"
                reset
            when "upgrade"
                upgrade
            when "sell"
                sell
            else
                if button.id["tower_"]
                    reset_picked_tower
                    @picked_tower_type = button.id[6].to_i
                    @picked_tower_level = 1
                end
            end
        end
    end

    def reset_picked_tower
        @picked_tower = nil
        @upgrade_btn.set_hidden(true)
        @sell_btn.set_hidden(true)
    end

    def button_down(id)
		case id
	    when Gosu::MsLeft
            grid = grid_area_clicked
            if grid
                x, y = grid
                tile = @game_map.tiles[x][y]
                case tile.obstacle_type
                when Obstacle_type::Tower
                    @picked_tower = tile
                    @upgrade_btn.set_hidden(false)
                    @sell_btn.set_hidden(false)
                when Obstacle_type::Empty
                    reset_picked_tower
                    if !@picked_tower_type.nil? 
                        tower_setting = SETTING["tower"][@picked_tower_type.to_s]
                        tower_price = tower_setting["level1"]["price"].to_i
                        if (tower_price < @fortress.money)
                            @game_map.tiles[x][y] = Tower.new(@picked_tower_type, x, y)
                            @fortress.money -= tower_price
                            @creeps.each { |creep| creep.update_game_map(@game_map) }
                        else
                            make_notification("Not enough money!")
                        end
                    end
                else
                    reset_picked_tower
                end
            end

            is_button_clicked?
	    end
	end
end


window = Roamers.new
window.show
