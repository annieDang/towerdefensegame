module ZOrder
    BACKGROUND,  UI , PLAYER= *0..2
end

module Obstacle_type
    Mountain = 0
    Tree = 1
    House = 2
    Tower = 3
    HQ = 4
    Infected_forest = 5
    Empty = 6
end

module Tower_type
    Range = 0
    Explosion = 1
    Effect = 2
end

module Creep_type
    Melee = 0
    Siege = 1
    Super = 2
end

module Tower_status
    Building = 0
    Built = 1
end

module Direction
    Up = 0
    Down = 1
    Left = 2
    Right = 3
end