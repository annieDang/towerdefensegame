require_relative 'setting'

def initializeVisitsAndParents width, height
    visited =  Array.new(width) do |x|
        Array.new(height) do |y|
            false
        end
    end
    parents =  Array.new(width) do |x|
        Array.new(height) do |y|
            nil
        end
    end
    [visited, parents]
end

# Pseudocode
# procedure BFS(G, root) is
#     let Q be a queue
#     label root as discovered
#     Q.enqueue(root)
#     while Q is not empty do
#         v := Q.dequeue()
#         if v is the goal then
#             return v
#         for all edges from v to w in G.adjacentEdges(v) do
#             if w is not labeled as discovered then
#                 label w as discovered
#                 Q.enqueue(w)

def is_empty_or_HQ tile
    return tile.obstacle_type == Obstacle_type::Empty || tile.obstacle_type == Obstacle_type::HQ
end

def find_path parents, enter, destination
    path = Array.new
    x, y = destination
    while !(x == enter.x and y == enter.y) do
        next_x = parents[x][y].x
        next_y = parents[x][y].y
        path << Direction::Up if(next_y - 1 == y)
        path << Direction::Down if(next_y + 1 == y)
        path << Direction::Left if(next_x - 1 == x)
        path << Direction::Right if(next_x + 1 == x)
        x = next_x
        y = next_y
    end
    path
end

def shortest_path game_map, enter, destination
    visited, parents = initializeVisitsAndParents(game_map.width, game_map.height)
    queue = Queue.new
    queue.push(enter)
    visited[enter.x][enter.y] = true
    found = false
    
    while !queue.empty? and !found do
        length = queue.length

        for k in 0..length-1 do
            current_tile = queue.shift
            if (current_tile.x == (destination.x + destination.width) )  && (current_tile.y == (destination.y + destination.height))
                puts "hit it"
                found = true;
                break
            end
            up = current_tile.y - 1
            if  up > 0 and !visited[current_tile.x][up] and is_empty_or_HQ(game_map.tiles[current_tile.x][up])
                queue.push(game_map.tiles[current_tile.x][up])
                parents[current_tile.x][up] = current_tile
                visited[current_tile.x][up] = true;
            end

            down = current_tile.y + 1
            if  down < (game_map.height - 1) and !visited[current_tile.x][down] and is_empty_or_HQ(game_map.tiles[current_tile.x][down])
                queue.push(game_map.tiles[current_tile.x][down])
                parents[current_tile.x][down] = current_tile
                visited[current_tile.x][down] = true;
            end

            left = current_tile.x - 1
            if  left > 0 and !visited[left][current_tile.y] and is_empty_or_HQ(game_map.tiles[left][current_tile.y])
                queue.push(game_map.tiles[left][current_tile.y])
                parents[left][current_tile.y] = current_tile
                visited[left][current_tile.y] = true;
            end

            right = current_tile.x + 1
            if  right < (game_map.width - 1) and !visited[right][current_tile.y] and is_empty_or_HQ(game_map.tiles[right][current_tile.y])
                queue.push(game_map.tiles[right][current_tile.y])
                parents[right][current_tile.y] = current_tile
                visited[right][current_tile.y] = true;
            end
        end
    end

    all_paths = Array.new
    for x in (destination.x)..(destination.x + destination.width - 1)
        for y in (destination.y)..(destination.y + destination.height - 1)
            all_paths << find_path(parents, enter, [x,y])
        end
    end 
    
    # since HQ includes many points, find the closest point
    shortest_path_indx = 0
    min = all_paths[0].length
    for inx in 1...all_paths.length do
        shortest_path_indx = inx if all_paths[inx].length < min
    end

    path = all_paths[shortest_path_indx]
    # path = find_path(parents, enter, [destination.x,destination.y])
    
    puts "path length :#{path.length}"
    puts "path :#{path}"
    path.reverse
end