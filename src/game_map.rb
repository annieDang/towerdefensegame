class GameMap
    attr_accessor :width, :height, :tiles

    def initialize(width, height)
        @width = width
        @height = height
        @tiles = []
        @fortress = nil
    end

    def random
        @tiles = Array.new(@width) do |x|
            Array.new(@height) do |y|
                random_tile(x,y) 
            end
        end
    end

    def random_terrain
        @tiles = Array.new(@width) do |x|
            Array.new(@height) do |y|
                tile = @tiles[x][y]
                return random_tile(x,y) if !tile
                
                case tile.obstacle_type
                when Obstacle_type::HQ
                    tile
                when Obstacle_type::Infected_forest
                    tile
                else
                    random_tile(x,y)
                end
            end
        end
    end

    def random_tile(x,y)
        case rand(23)
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

    # attacking point 
    def add_Hq(fortress)
        @fortress = fortress
        for x in (fortress.x)..(fortress.x + fortress.width - 1)
            for y in (fortress.y)..(fortress.y + fortress.height - 1)
                @tiles[x][y] = Obstacle.new(Obstacle_type::HQ, x, y)
            end
        end
    end

    # spawning point
    def addEntrance(land)
        @tiles[land.x][land.y] = Obstacle.new(Obstacle_type::Entrance, land.x, land.y)
    end

    def remove_towers
        @width.times.each do |x|
            @height.times.each do |y|
              if @tiles[x][y].obstacle_type == Obstacle_type::Tower
                @tiles[x][y] = Obstacle.new(Obstacle_type::Empty, x, y)
              end
            end
        end
    end

    def draw_grid
        color = Gosu::Color.argb(0xff_808080)
        egde_x = @width * Engine::PlayState::TileSize + Engine::PlayState::LeftMenuWidth
        egde_y = @height * Engine::PlayState::TileSize
        for x in 0..@width do
            loc_x = x * Engine::PlayState::TileSize + Engine::PlayState::LeftMenuWidth
            $window.draw_line(loc_x, 0 , color, loc_x, egde_y, color, ZOrder::BACKGROUND, mode=:default)
        end
        
        for y in 0..@height do
            loc_x = Engine::PlayState::LeftMenuWidth
            loc_y = y * Engine::PlayState::TileSize
            $window.draw_line(loc_x, loc_y, color,  egde_x, loc_y, color, ZOrder::BACKGROUND, mode=:default)
        end
    end

    def draw
        draw_grid
        return if !@tiles

        # Very primitive drawing function:
        # Draws all the tiles, some off-screen, some on-screen.
        drawedHQ = false
        @width.times do |x|
            @height.times do |y|
                tile = @tiles[x][y]
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

    def grid_area_clicked?
        !grid_area_clicked.nil?
    end

    def grid_area_clicked
        @width.times do |x|
           @height.times do |y|
                leftX, topY= map_location(x, y)
                rightX = leftX + Engine::PlayState::TileSize
                bottomY = topY + Engine::PlayState::TileSize
                if Engine::Game.area_clicked(leftX, topY, rightX, bottomY)
                    return [x, y]
                end
            end
        end
        nil
    end
end