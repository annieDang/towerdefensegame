class Infected_land < Obstacle
    attr_accessor :obstacle_type, :x, :y, :image, :path

    def initialize(type, x, y)
        super(type, x, y)
    end

end