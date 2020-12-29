module Engine
  # This game state is the playing screen
  class PlayState < GameState
    LeftMenuWidth = 200
    TileSize = 48
    # Constructor
    def initialize
      # fonts that needed
      @group_font = Game::fonts["big"]
      @info_font = Game::fonts["small"]
      @status_font = Game::fonts["notification"]

      # this is for game information
      @creeps_tiles = Game::images["creeps"]

      # create game world
      @gamemap = GameMap.new((Game::ScreenWidth - LeftMenuWidth)/TileSize, Game::ScreenWidth/TileSize)
      @gamemap.random

      @fortress = Fortress.new(1, 13, 2,2)
      @gamemap.add_Hq(@fortress)

      @entrance = Entrance.new( 13, 1) 
      @gamemap.addEntrance(@entrance)
      @entrance.path = get_shortest_path(@entrance)

      # create all buttons in UI
      @buttons = []
      create_buttons

      # for showing information of selected tower
      @picked_tower = nil
      @picked_tower_type = nil
      @picked_tower_level = nil

      @notification = nil
      @notification_end_time = Gosu.milliseconds
      
      @creeps = []
      @last_move_time = Gosu.milliseconds

      create_sounds

      # start the game. Set game status
      start_game
    end

    def start_game
      @game_status = Game_status::Running

      @start_game = Gosu.milliseconds
      @time = 0
    end

    # calculate shortest path 
    def get_shortest_path(entrance)
      shortest_path = shortest_path(entrance, @fortress)
      # when there is no path from entrance to the fortress
      # recreate all terrain of game map
      while !shortest_path
        @game_map.random_terrain
        shortest_path = shortest_path(entrance, @fortress)
      end
      shortest_path
    end

    def create_sounds
      @sound = Hash.new
      @sound["kill"] = Gosu::Song.new("./media/sound/Pika Scream.mp3")
      @sound["attack"] = Gosu::Song.new("./media/sound/Pikaaaa.mp3")
      @sound["shooting"] = Gosu::Song.new("./media/sound/shoot.mp3")
    end

    # add buttons
    def create_buttons
      @buttons << Button.new(20, 180, 70, 40, "Pause", "start")
      @buttons << Button.new(110, 180, 70, 40, "Reset", "reset")

      start_at =  290
      SETTING["level"][@fortress.level.to_s]["towers"].each do |tower_type|
          tower_setting = SETTING["tower"][tower_type.to_s]
          btn = Button.new(20, start_at, 150, 40, tower_setting["name"], "tower_#{tower_type}")
          btn.set_left_align
          @buttons << btn
          start_at += 60
      end

      start_at =  470
      @upgrade_btn = Button.new(10, start_at + 170, 80, 40, "Upgrade", "upgrade")
      @sell_btn = Button.new(110, start_at + 170, 80, 40, "Sell", "sell")
      @upgrade_btn.set_hidden(true)
      @sell_btn.set_hidden(true)
      @buttons << @upgrade_btn
      @buttons << @sell_btn

      @buttons << Button.new(5, 700, 190, 40,"Back to menu", "main_menu" )
    end
    
    # Updates the main menu screen elements
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
          reset_level
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
          @shooting = false
          Tower.towers.each do |tower|
              @creeps.each do |creep|
                  if(tower.is_shooting?(creep) and tower.tower_type != Tower_type::Effect)
                      @shooting = true
                      break
                  end
              end
              break if @shooting
          end

          # play or stop shooting sound 
          if !@shooting
              @sound["shooting"].stop if @sound["shooting"].playing?
          elsif !@sound["shooting"].playing?
              play_sound("shooting")
          end

          Tower.towers.each { |tower| tower.attack(@creeps) }
                
          # move the creeps
          if Gosu.milliseconds - @last_move_time > 100
            @creeps.each { |creep| creep.move(@fortress, @gamemap) }
            @last_move_time = Gosu.milliseconds
          end

          # remove the died | exploded
          @creeps.each { |creep| @fortress.money += creep.profit if creep.bury?}
          @creeps.reject! do |creep| 
              if creep.bury? 
                  play_sound("kill")
                  true
              end
          end
          @creeps.reject! do |creep| 
              if creep.exploded_done?
                  play_sound("attack")
                  true
              end
          end

          # kill the died
          @creeps.each {|creep|  creep.kill! if creep.health <0 }

          # spawn a creep each 1s
          # number of creep on the field is defined by setting.json
          if(@creeps.length < @fortress.number_of_creeps)
              @creeps << sprawn_creep if(Gosu.milliseconds - (@last_sprawn_time || 0) > 1000)
          end
      end
    end

    # spawn a creep 
    def sprawn_creep
      @last_sprawn_time = Gosu.milliseconds
      zombies = @fortress.wave["zombie"]
      # generate a random number (n) between 0 and total % 
      # all all creep (noramlly it should be 100)
      # loop though all creep types and substract n with its percentage
      # if result < 0 return the creep type
      # for example 30%,40%,30%
      # 30% n will be from 0 - 30 
      # 40% n will be from 31-70
      # 30% n will be from 71 to 100
      sum = zombies.inject(0){|sum,x| sum + x["count"].to_i }
      random_no = rand(sum)
      zombies.each do |zombie|
        if ((random_no -= zombie["count"]) < 0)
          return Creep.new(zombie["type"], @entrance.x, @entrance.y, @entrance.path) 
        end
      end
    end

    def play_sound(name)
      playing = nil
      @sound.each do |key, value|
         if value.playing? 
              playing = key
              break
         end
      end
      return if playing and name == "shooting" and playing != name
      if(playing != name)
          @sound[name].volume = 0
          @sound[name].play 
      end
    end
    
    # Draws the main menu screen elements
    def draw
      @gamemap.draw

      draw_left_menu
      @buttons.each {|button|  button.draw }

      dragging_tower

      draw_paths

      @picked_tower.draw_indicator() if @picked_tower

      draw_game_info

      # draw creeps
      @creeps.each { |creep| creep.spawn }

       # game status
       draw_status
    end

    def draw_game_status text
      height = @status_font.height
      width = @status_font.text_width(text, scale_x = 1)
      x = (Game::ScreenWidth - LeftMenuWidth)/2 + LeftMenuWidth
      y = Game::ScreenHeight/2
      $window.draw_rect(x - width/2 - 50 ,y - height/2 - 10, width + 100, height + 20, Gosu::Color::GRAY, ZOrder::NOTIFICATION)
      @status_font.draw(text, x - width/2 ,y - height/2, ZOrder::NOTIFICATION, 1.0, 1.0, Gosu::Color::WHITE)
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
          x = (Game::ScreenWidth - LeftMenuWidth)/2 + LeftMenuWidth
          y = Game::ScreenHeight/2
          $window.draw_rect( x - width/2 - 50 , y - height/2 - 10, width + 100, height + 20, Gosu::Color::BLACK, ZOrder::NOTIFICATION)
          @status_font.draw(@notification, x - width/2 ,  y - height/2, ZOrder::NOTIFICATION, 1.0, 1.0, Gosu::Color::WHITE)
      end

    end
    
    # show moving path of creeps
    def draw_paths
      x = @entrance.x
      y = @entrance.y
      for step in 0..(@entrance.path.length - 1)
        x, y = cal_grid(@entrance.path[step], x, y)
        start_x = x * TileSize + LeftMenuWidth
        start_y = y * TileSize
        $window.draw_rect(start_x, start_y, TileSize, TileSize, Gosu::Color.new(76, 31, 12), ZOrder::BACKGROUND)
      end
    end

    def draw_game_info
      offset_left = 30
      y = 20
      @group_font.draw("TIME: #{@time}", offset_left, y, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
      
      #home info
      @group_font.draw("Money: #{@fortress.money} X", offset_left, y + 20, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
      coin_img = Gosu::Image.new("./media/coin.png")
      coin_img.draw(offset_left + 120, y + 14, ZOrder::TOWER, 28.0/coin_img.width,  28.0/coin_img.height)
      
      start_at = y + 50
      offset_left +=20 
      @info_font.draw("Pokemons: #{@fortress.number_of_creeps}", offset_left, start_at, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
     
      start_at +=5
      @fortress.wave["zombie"].each do |each| 
          name = SETTING["creep"][each["type"]]["name"]
          @info_font.draw("#{name}: #{each["count"]}%", offset_left, start_at + 20, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
          img_loc = SETTING["creep"][each["type"]]["tile_loc"]
          @creeps_tiles[(img_loc-1)*3].draw(offset_left + 70, start_at , ZOrder::UI, 1, 1)
          start_at += 25
      end

    end

    def reset
      # reset level: time,creep, money
      reset_level
      
      # reset towers
      reset_towers
    end

    def reset_level
      @start_game = Gosu.milliseconds
      @time = 0
      @creeps =[]
      @picked_tower = nil

      @fortress.health = SETTING["level"][@fortress.level.to_s]["health"]
      @fortress.money = SETTING["level"][@fortress.level.to_s]["money"]
      @game_status = Game_status::Running
    end

    def reset_towers
      @gamemap.remove_towers
      Tower.clear_towers
    end
    
    def is_game_over?
      if @fortress.health <= 0
          @game_status = Game_status::Game_over
          true 
      end
      false
    end

    def draw_left_menu
      store_lable_y = 240
      @group_font.draw("STORE", 65, store_lable_y, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
      $window.draw_line(20, store_lable_y + 30, Gosu::Color::WHITE, LeftMenuWidth - 20, store_lable_y + 30, Gosu::Color::WHITE, ZOrder::UI, mode=:default)

      # draw_tower_list
      start_at = store_lable_y + 30
      SETTING["level"][@fortress.level.to_s]["towers"].each do |tower_type|
          tower_setting = SETTING["tower"][tower_type.to_s]
          @image = Gosu::Image.new(tower_setting["level1"]["image"])
          @image.draw(120, start_at, ZOrder::UI, (TileSize * 1.0) /@image.width,  (TileSize * 1.0) /@image.height)
          start_at += 60
      end
      information_lable_y = store_lable_y + 220
      @group_font.draw("INFORMATION", 35, information_lable_y, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
      $window.draw_line(20, information_lable_y+30, Gosu::Color::WHITE, LeftMenuWidth - 20, information_lable_y +30, Gosu::Color::WHITE, ZOrder::UI, mode=:default)
      
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
      y = 510

      image = Gosu::Image.new(setting["level#{picked_tower_level}"]["image"])
      image.draw(x + 80, y + 40, ZOrder::BACKGROUND, (TileSize * 1.0) /image.width,  (TileSize * 1.0) /image.height)
     
      @info_font.draw("Tower name: #{setting["name"]}", x, y, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
      detail_setting = setting["level#{picked_tower_level}"]
      @info_font.draw("Range: #{detail_setting["range"]}", x, y + 20, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
      @info_font.draw("Damage: #{detail_setting["damage"]}", x, y + 40, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
      @info_font.draw("Price: #{detail_setting["price"]}", x, y + 60, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
      @info_font.draw("Sell_price: #{detail_setting["price"]/2}", x, y + 80, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
      @info_font.draw("Cool down time: #{detail_setting["cool_down"]}", x, y + 100, ZOrder::UI, 1.0, 1.0, Gosu::Color::WHITE)
    end

    def make_notification(info, time_to_show = 1000)
      @notification = info
      @notification_end_time = Gosu.milliseconds + time_to_show
    end

    def showing_notification?
      (Gosu.milliseconds - @notification_end_time) > 0
    end

    def dragging_tower
      grid = @gamemap.grid_area_clicked
      if !@picked_tower_type.nil? and grid
          x, y = grid
          obstacle = @gamemap.tiles[x][y]
          if obstacle.obstacle_type == Obstacle_type::Empty
              setting = SETTING["tower"][@picked_tower_type.to_s]
              @image = Gosu::Image.new(setting["level1"]["image"])
              start_x = x * TileSize + LeftMenuWidth
              start_y = y * TileSize
              @image.draw(start_x, start_y, ZOrder::UI, (TileSize * 1.0) /@image.width,  (TileSize * 1.0) /@image.height)
              radius =  setting["level1"]["range"].to_f
              draw_circle(start_x + TileSize/2, start_y + TileSize/2, radius/2, ZOrder::TOWER)
          else
              draw_x x, y if obstacle.obstacle_type != Obstacle_type::Tower and obstacle.obstacle_type != Obstacle_type::HQ
          end
      end
    end
    
    def draw_x x, y
      leftX = x * TileSize + LeftMenuWidth
      topY = y * TileSize
      rightX = leftX + TileSize
      bottomY = topY + TileSize
      thickness = 4
      color =  Gosu::Color::RED
      $window.draw_quad(leftX - thickness/2, topY, color, leftX + thickness/2, topY, color, rightX - thickness/2, bottomY, color, rightX + thickness/2, bottomY, color, ZOrder::UI)
      $window.draw_quad(leftX + TileSize - thickness/2, topY, color, leftX + TileSize + thickness/2, topY, color, rightX - TileSize - thickness/2, bottomY, color, rightX - TileSize + thickness/2, bottomY, color,ZOrder::UI)
    end

    def button_down(id)
      case id
        when Gosu::MsLeft
          button_handler
        end
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

    def button_handler
      # if grid is clicked
      grid = @gamemap.grid_area_clicked()
      if grid and @game_status == Game_status::Running
        x, y = grid
        tile = @gamemap.tiles[x][y]
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
                    @gamemap.tiles[x][y] = Tower.new(@picked_tower_type, x, y)
                    @fortress.money -= tower_price
                else
                    make_notification("Not enough money!")
                end
                @picked_tower_type = nil
            end
        else
            reset_picked_tower
        end
      end

      # handle button event
      @buttons.each do |button|
          next if button.hidden?
          next if !button.isHovered?
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
          when "main_menu"
            reset
            Game.game_state = MenuState
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

      tower = @gamemap.tiles[@picked_tower.x][@picked_tower.y]
      if(tower.obstacle_type == Obstacle_type::Tower)
          tower.upgrade
          @fortress.money -= @picked_tower.get_upgrade_price 
          @fortress.money  = 0 if @fortress.money<0
      end
    end

    def sell
      @gamemap.tiles[@picked_tower.x][@picked_tower.y] = Obstacle.new(Obstacle_type::Empty, @picked_tower.x, @picked_tower.y)
      Tower.towers.reject! {|tower| tower.x == @picked_tower.x  and tower.y == @picked_tower.y }
      @fortress.money += @picked_tower.sell_price

      reset_picked_tower
    end
  
  end 
end