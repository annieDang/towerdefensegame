def cal_grid move, last_x, last_y
    x = last_x
    y = last_y
    case move
    when Direction::Up
        y = last_y - 1
    when Direction::Down
        y = last_y + 1
    when Direction::Left
        x = last_x - 1
    when Direction::Right
        x = last_x + 1
    end
    [x,y]
end