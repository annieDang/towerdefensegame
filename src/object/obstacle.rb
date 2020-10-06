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