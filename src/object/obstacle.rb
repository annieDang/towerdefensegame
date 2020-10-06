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

    def draw 
        start_x = @x * TILE_OFFSET + SIDE_WIDTH
        start_y = @y * TILE_OFFSET
        @image.draw(start_x, start_y, ZOrder::BACKGROUND, (TILE_OFFSET * 1.0) /@image.width,  (TILE_OFFSET * 1.0) /@image.height)
    end
end