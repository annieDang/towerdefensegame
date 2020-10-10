require 'rubygems'
require 'gosu'
require 'json'

require_relative 'setting'

require_relative 'sprite/creep'

require_relative 'utils/button'
require_relative 'utils/find_path'
require_relative 'utils/health_bar'
require_relative 'utils/circle'
require_relative 'utils/grid_helper'

require_relative 'object/obstacle'
require_relative 'object/fortress'
require_relative 'object/tower'
require_relative 'object/infected_land'

WIDTH, HEIGHT = 1016, 768
SIDE_WIDTH = 200
TILE_OFFSET = 48

# Map class holds and draws tiles and gems.
class GameMap
    attr_accessor :width, :height, :tiles, :side_width
end

def regenerate_terrain(game_map)
    game_map.width = (WIDTH - SIDE_WIDTH)/TILE_OFFSET
    game_map.height = HEIGHT/TILE_OFFSET

    game_map.tiles = Array.new(game_map.width) do |x|
        Array.new(game_map.height) do |y|
            case game_map.tiles[x][y].obstacle_type
            when Obstacle_type::HQ
                game_map.tiles[x][y]
            when Obstacle_type::Infected_forest
                game_map.tiles[x][y]
            else
                case rand(1000)%23
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
      end
      game_map
end

def setup_game_map
    game_map = GameMap.new
    game_map.width = (WIDTH - SIDE_WIDTH)/TILE_OFFSET
    game_map.height = HEIGHT/TILE_OFFSET

    game_map.tiles = Array.new(game_map.width) do |x|
        Array.new(game_map.height) do |y|
            case rand(1000)%23
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
        $window = self

        self.caption = "Roamers"
        @ground = Gosu::Image.new("media/ground.jpeg")
        @circle = Gosu::Image.new("media/circle.png")
        @pokemon_tiles = Gosu::Image.load_tiles("./media/pokemons.png", 32, 32)

        # generate a random map full with obstacles 
        # and then add hq, infected land
        @game_map = setup_game_map 
        puts "Map is generated width #{@game_map.width} heigh #{@game_map.height}"
        @fortress = Fortress.new("MAD POKEMONS", 2, 9, Obstacle_type::HQ, 2, 2)
       
        @infected_lands = Array.new
        bad_land = Infected_land.new(Obstacle_type::Infected_forest, 9, 2) 
        add_infected_land(bad_land,@game_map)
        bad_land.path = get_shortest_path(bad_land)
        @infected_lands << bad_land
        
        add_Hq(@fortress,@game_map)

        @creeps = Array.new

        @picked_tower_type = Tower_type::Range
        @picked_tower_level = 1
        @picked_tower = nil
        
        create_buttons
        
        start_game

        @notification = nil
        @notification_end_time = Gosu.milliseconds

        @last_move_time = Gosu.milliseconds

        create_fonts()
        
    end

    def start_game
        @song = Gosu::Song.new("media/sound/background_normal.mp3") 
        @song.volume = 0.2
        @song.play(true)

        @game_status = Game_status::Running

        @start_game = Gosu.milliseconds
        @time = 0
    end

    def create_fonts
        @group_font = Gosu::Font.new(20)
        @status_font = Gosu::Font.new(25)
        @button_font = Gosu::Font.new(15)
        @item_name_font = Gosu::Font.new(14)
        @info_font = Gosu::Font.new(15)
    end

    def get_shortest_path(bad_land)
        shortest_path = shortest_path(bad_land, @fortress)
        while !shortest_path
            regenerate_terrain(@game_map)
            shortest_path = shortest_path(bad_land, @fortress)
        end
        shortest_path
    end

    def create_buttons
        Button.new(20, 90, 70, 40, "Pause", "start")
        Button.new(110, 90, 70, 40, "Reset", "reset")

        start_at =  200
        SETTING["level"][@fortress.level.to_s]["towers"].each do |tower_type|
            tower_setting = SETTING["tower"][tower_type.to_s]
            btn = Button.new(20, start_at, 150, 40, tower_setting["name"], "tower_#{tower_type}")
            btn.set_left_align
            start_at += 60
        end
        
        @upgrade_btn = Button.new(10, start_at + 170, 80, 40, "Upgrade", "upgrade")
        @sell_btn = Button.new(110, start_at + 170, 80, 40, "Sell", "sell")
        @upgrade_btn.set_hidden(true)
        @sell_btn.set_hidden(true)

        start_y = 650
        start_x = 5
        step = 50
        width = 90
        height = 40
        Button.new(start_x, start_y, width, height, "Add land", "more_zombies")
        Button.new(start_x + 100, start_y, width, height, "Random map", "creat_random_map")
        Button.new(start_x, start_y+ step, width + 100, height,"Graph test", "load_map" )
    end

    def make_notification(info, time_to_show = 1000)
        @notification = info
        @notification_end_time = Gosu.milliseconds + time_to_show
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

         # draw paths
         draw_paths

        # show tower indicator
        dragging_tower

        # game status
        draw_status

        #draw_buttons
        Button.buttons.each { |button| draw_button(button) if !button.hidden }
    end

    def draw_game_status text
        height = @status_font.height
        width = @status_font.text_width(text, scale_x = 1)
        draw_rect((WIDTH - SIDE_WIDTH)/2 - width/2 - 50 + SIDE_WIDTH, HEIGHT/2 - height/2 - 10, width + 100, height + 20, Gosu::Color::GRAY, ZOrder::NOTIFICATION)
        @status_font.draw(text, (WIDTH - SIDE_WIDTH)/2 - width/2 + SIDE_WIDTH,  HEIGHT/2 - height/2, ZOrder::NOTIFICATION, 1.0, 1.0, Gosu::Color::WHITE)
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
            draw_rect((WIDTH - SIDE_WIDTH)/2 - width/2 - 50 + SIDE_WIDTH, HEIGHT/2 - height/2 - 10, width + 100, height + 20, Gosu::Color::BLACK, ZOrder::NOTIFICATION)
            @status_font.draw(@notification, (WIDTH - SIDE_WIDTH)/2  - width/2 + SIDE_WIDTH,  HEIGHT/2 - height/2, ZOrder::NOTIFICATION, 1.0, 1.0, Gosu::Color::WHITE)
        end

    end

    def draw_ui
        @ui_offset = 5
        draw_left_menu
        draw_game_info
    end

    def draw_left_menu
        home_lable_y = 30
        @group_font.draw("#{@fortress.name}", 30, home_lable_y, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
        draw_line(20, home_lable_y + 30, Gosu::Color::WHITE, SIDE_WIDTH - 20, home_lable_y + 30, Gosu::Color::WHITE, ZOrder::UI, mode=:default)

        store_lable_y = 150
        @group_font.draw("STORE", 65, store_lable_y, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
        draw_line(20, store_lable_y + 30, Gosu::Color::WHITE, SIDE_WIDTH - 20, store_lable_y + 30, Gosu::Color::WHITE, ZOrder::UI, mode=:default)

        # draw_tower_list
        start_at = store_lable_y + 30
        SETTING["level"][@fortress.level.to_s]["towers"].each do |tower_type|
            tower_setting = SETTING["tower"][tower_type.to_s]
            @image = Gosu::Image.new(tower_setting["level1"]["image"])
            @image.draw(120, start_at, ZOrder::UI, (TILE_OFFSET * 1.0) /@image.width,  (TILE_OFFSET * 1.0) /@image.height)
            start_at += 60
        end
        information_lable_y = store_lable_y + 220
        @group_font.draw("INFORMATION", 35, information_lable_y, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
        draw_line(20, information_lable_y+25, Gosu::Color::WHITE, SIDE_WIDTH - 20, information_lable_y +25, Gosu::Color::WHITE, ZOrder::UI, mode=:default)
        
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
        x = 30
        y = 420

        image = Gosu::Image.new(setting["level#{picked_tower_level}"]["image"])
        image.draw(x + 80, y + 40, ZOrder::BACKGROUND, (TILE_OFFSET * 1.0) /image.width,  (TILE_OFFSET * 1.0) /image.height)
       
        @info_font.draw("Tower name: #{setting["name"]}", x, y, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
        detail_setting = setting["level#{picked_tower_level}"]
        @info_font.draw("Range: #{detail_setting["range"]}", x, y + 20, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
        @info_font.draw("Damage: #{detail_setting["damage"]}", x, y + 40, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
        @info_font.draw("Price: #{detail_setting["price"]}", x, y + 60, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
        @info_font.draw("Sell_price: #{detail_setting["price"]/2}", x, y + 80, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
        @info_font.draw("Cool down time: #{detail_setting["cool_down"]}", x, y + 100, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)

        # draw_line(20, y + 180, Gosu::Color::WHITE, SIDE_WIDTH - 20, y + 180, Gosu::Color::WHITE, ZOrder::UI, mode=:default)
    end

    def draw_game_info
        offset_left = WIDTH - 150
        @group_font.draw("TIME: #{@time}", offset_left, 10, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
        
        #home info
        @group_font.draw("Money: #{@fortress.money}", offset_left, 30, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
        coin_img = Gosu::Image.new("./media/coin.png")
        coin_img.draw(offset_left + 50, 30, ZOrder::TOWER, 5.0/coin_img.width,  5.0/coin_img.height)
        
        start_at = 60
        @info_font.draw("Pokemons: #{@fortress.number_of_creeps}", offset_left, start_at, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
        draw_line(offset_left, start_at + 15, Gosu::Color::WHITE, WIDTH, start_at + 15, Gosu::Color::WHITE, ZOrder::UI, mode=:default)
       
        start_at +=5
        @fortress.wave["zombie"].each do |each| 
            name = SETTING["zombies"][each["type"]]["name"]
            @info_font.draw("#{name}: #{each["count"]}%", offset_left, start_at + 20, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
            img_loc = SETTING["zombies"][each["type"]]["tile_loc"]
            @pokemon_tiles[(img_loc-1)*3].draw(offset_left + 70, start_at , ZOrder::UI, 1, 1)
            start_at += 25
        end

    end

    def draw_button button 
        color = button.color
        color = Gosu::Color::BLUE if area_clicked(button.x, button.y, button.x + button.width, button.y + button.height)
        draw_rect(button.x, button.y, button.width, button.height, color || Gosu::Color.new(107,106,76))
        
        width = @button_font.text_width(button.label, scale_x = 1)
        height = @button_font.height

        if button.left_align
            @button_font.draw(button.label, button.x + 20, button.y + (button.height - height)/2, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
        else
            @button_font.draw(button.label, button.x + (button.width - width)/2, button.y + (button.height - height)/2, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
        end
    end

    def draw_paths
        @infected_lands.each do |land|
            x = land.x
            y = land.y
            for step in 0..(land.path.length - 1)
                x, y = cal_grid(land.path[step], x, y)
                start_x = x * TILE_OFFSET + SIDE_WIDTH
                start_y = y * TILE_OFFSET
                draw_rect(start_x, start_y, TILE_OFFSET, TILE_OFFSET, Gosu::Color.new(76, 31, 12), ZOrder::BACKGROUND)
            end
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
    
    # indicator lines
    def draw_indicator x, y, color
        start_x = x * TILE_OFFSET + SIDE_WIDTH
        start_y = y * TILE_OFFSET
        indicator = Gosu::Image.new(Circle.new(2))
        indicator.draw(start_x + TILE_OFFSET/2, start_y + TILE_OFFSET/2, ZOrder::UI, 1, 1, color)
    end

    def draw_grid
        color = Gosu::Color.argb(0xff_808080)
        for x in 0..@game_map.width do
            draw_line(x * TILE_OFFSET + SIDE_WIDTH, 0 , color,  x * TILE_OFFSET + SIDE_WIDTH, HEIGHT, color, ZOrder::BACKGROUND, mode=:default)
        end
        
        for y in 0..@game_map.height do
            draw_line(SIDE_WIDTH, y * TILE_OFFSET, color,  WIDTH, y * TILE_OFFSET, color, ZOrder::BACKGROUND, mode=:default)
        end
    end

    def sprawn_creep
        @last_sprawn_time = Gosu.milliseconds
        zombies = @fortress.wave["zombie"]
        sum = zombies.inject(0){|sum,x| sum + x["count"].to_i }

        random_no = rand(sum)
        zombies.each do |zombie|
            land_indx = rand(@infected_lands.length)
            land = @infected_lands[land_indx]
            return Creep.new(zombie["type"], land.x, land.y, land.path, @mapping_map) if ((random_no -= zombie["count"]) < 0)
        end
    end

    def update
        @notification = nil if showing_notification?
        
        return if @game_status == Game_status::Game_over || @game_status == Game_status::Won
        return if is_game_over?

        if @game_status == Game_status::Next_level and !showing_notification?
            if @fortress.level >=3
                @fortress.level = 3
                @game_status = Game_status::Won
                return
            end

            @fortress.next_level
            while (@infected_lands.length < @fortress.number_of_infected_land)
                create_random_infected_land
            end
            reset
            return
        end

        if @game_status == Game_status::Running
            @time = (Gosu.milliseconds - @start_game)/1000 if @game_status == Game_status::Running
            if @time >= SETTING["time_per_level"]
                make_notification("Next Levlel", 2000)
                @game_status = Game_status::Next_level
                return
            end

            # attack creeps
            Tower.attack(@creeps)

            # move them
            if Gosu.milliseconds - @last_move_time > 100
                @creeps.each { |creep| creep.move(@fortress, @game_map) }
                @last_move_time = Gosu.milliseconds
            end

            # remove the died 
            @creeps.each { |creep| @fortress.money += creep.profit if creep.bury?}
            @creeps.reject! {|creep| creep.bury? }
            @creeps.reject! {|creep| creep.exploded_done? }

            # kill the died
            @creeps.each { |creep| creep.kill! if creep.health <0}

            if(@creeps.length < @fortress.number_of_creeps)
                @creeps << sprawn_creep if(Gosu.milliseconds - (@last_sprawn_time || 0) > 500)
            end
        end

    end

    def showing_notification?
        (Gosu.milliseconds - @notification_end_time) > 0
    end

    def is_game_over?
        if @fortress.health <= 0
            @game_status = Game_status::Game_over
            true 
        end
        false
    end

    def needs_cursor? 
        true 
    end

    def reset
        @start_game = Gosu.milliseconds
        @time = 0
        @creeps =[]

        @fortress.health = SETTING["level"][@fortress.level.to_s]["health"]
        @fortress.money = SETTING["level"][@fortress.level.to_s]["money"]

        # reset towers
        @game_map.width.times.each do |x|
            @game_map.height.times.each do |y|
                if @game_map.tiles[x][y].obstacle_type == Obstacle_type::Tower
                    @game_map.tiles[x][y] = Obstacle.new(Obstacle_type::Empty, x, y)
                end
            end
          end
        Tower.clear_towers

        @game_status = Game_status::Running
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
        if(tower.obstacle_type == Obstacle_type::Tower)
            tower.upgrade
            @fortress.money -= @picked_tower.get_upgrade_price 
        end
    end

    def sell
        @game_map.tiles[@picked_tower.x][@picked_tower.y] = Obstacle.new(Obstacle_type::Empty, @picked_tower.x, @picked_tower.y)
        Tower.towers.reject! {|tower| tower.x == @picked_tower.x  and tower.y == @picked_tower.y }
        @fortress.money += @picked_tower.sell_price

        reset_picked_tower
    end

    def create_random_infected_land
        rand_x = rand(@game_map.width - 1)
        rand_y = rand(@game_map.height - 1)
        
        while (rand_x - @fortress.x).abs <5 and (rand_y - @fortress.y).abs <5
            rand_x = rand(@game_map.width - 1)
            rand_y = rand(@game_map.height - 1)
        end
        
        bad_land = Infected_land.new(Obstacle_type::Infected_forest, rand_x, rand_y) 
        add_infected_land(bad_land,@game_map)
        bad_land.path = get_shortest_path(bad_land)
        @infected_lands << bad_land
    end

    def create_random_map
        @game_map = setup_game_map
        @fortress.x = rand(1..@game_map.width - 2)
        @fortress.y = rand(1..@game_map.height - 2)
        @fortress.health = SETTING["level"][@fortress.level.to_s]["health"]
        @fortress.money = SETTING["level"][@fortress.level.to_s]["money"]
        
        @infected_lands = Array.new
        create_random_infected_land()

        add_Hq(@fortress,@game_map)
        
        @picked_tower = nil
        @start_game = Gosu.milliseconds
        @time = 0
        @creeps =[]

        # reset towers
        Tower.clear_towers

        @game_status = Game_status::Running
    end
    
    def button_handler
        Button.buttons.each do |button|
            next if button.hidden?
            next if !area_clicked(button.x, button.y, button.x + button.width, button.y + button.height)
            case button.id
            when "start"
                start_pause
                button.label = "Pause" if (@game_status == Game_status::Running)
                button.label = "Start" if (@game_status == Game_status::Pause)
            when "reset"
                reset
            when "upgrade"
                return if !@picked_tower
                upgrade
            when "sell"
                return if !@picked_tower
                sell
            when "load_map"

            when "creat_random_map"
                create_random_map
            when "more_zombies"
                create_random_infected_land()
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
                        else
                            make_notification("Not enough money!")
                        end
                    end
                else
                    reset_picked_tower
                end
            end

            button_handler
	    end
    end
    
    # Sourced from https://gist.github.com/ippa/662583
    def draw_circle(cx,cy,r, z = 9999,color = Gosu::Color::GREEN, step = 10)
        0.step(360, step) do |a1|
        a2 = a1 + step
        draw_line(cx + Gosu.offset_x(a1, r), cy + Gosu.offset_y(a1, r), color, cx + Gosu.offset_x(a2, r), cy + Gosu.offset_y(a2, r), color, z)
        end
    end
end

window = Roamers.new
window.show
