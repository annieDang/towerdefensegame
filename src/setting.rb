def load_settings
    file = File.read('./settings.json')
    JSON.parse(file)
end

SETTING = load_settings


module Obstacle_type
    Mountain = 0
    Tree = 1
    House = 2
    Tower = 3
    HQ = 4
    Entrance = 5
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

module Game_status
   Running = 0
   Pause = 1
   Won = 2
   Game_over = 3
   Next_level = 4
end