class Button
    @@buttons = []
    @@draw_fun = nil
    attr_accessor :x, :y, :width, :height, :label, :id, :hidden, :left_align
    def initialize(x, y, width, height, label, id)
        @x = x
        @y = y
        @width = width
        @height = height
        @label = label
        @id = id

        @hidden = false

        @@buttons << self
    end

    def set_left_align
        @left_align = true
    end

    def set_hidden hidden
        @hidden = hidden
    end

    def self.buttons
        @@buttons
    end
end