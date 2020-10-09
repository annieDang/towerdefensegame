def draw_health_bar(current_health, max_health, x, y, width, height)
    percent = calc_health_percentage(current_health, max_health)
    ratio = (health * 1.0)/max_health
    if percent >= 65
        $window.draw_rect(x, y, (ratio * width).to_i, height, Gosu::Color::BLUE, 999)
    elsif percent >= 45
        $window.draw_rect(x, y, (ratio * width).to_i, height, Gosu::Color::YELLOW, 999)
    elsif percent >= 25
        $window.draw_rect(x, y, (ratio * width).to_i, height, Gosu::Color::RED, 999)
    else
        $window.draw_rect(x, y, (ratio * width).to_i, height, Gosu::Color.new(139,0,0), 999)
    end
end
  
def calc_health_percentage(current_health, max_health)
    ((health * 1.0 )/max_health)*100
end

  