class Entrance < Obstacle
    attr_accessor :obstacle_type, :x, :y, :image, :path

    def initialize(x, y)
        super(Obstacle_type::Entrance, x, y)
    end

end