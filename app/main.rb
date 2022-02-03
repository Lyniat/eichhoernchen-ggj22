class State
  MENU = 0
  STARTING = 1
  PLAYING = 2
end

class Resources
  SPR_MENU = 'sprites/titel_2.png'
  SPR_SQUIRREL_FRONT = 'sprites/squirrel_front.png'
  SPR_GROUND = 'sprites/ground.png'
  SPR_SQUIRREL = 'sprites/squirrel.png'
  FONT = 'fonts/shpinscher.ttf'
end

class Constants
  WIDTH = 1280
  HEIGHT = 720
  TREE_WIDTH = 12
  TREE_HEIGHT = 60
  TILE_SIZE = 64
end

class Tiles
  BARK_LEFT = 0
  BARK = 1
  BARK_HOLE = 2
  BARK_RIGHT = 3
end

class Squirrel
  attr_reader :x,:y
  def initialize(args,cam,x, y,size)
    @sprites = args.outputs.sprites
    @camera = cam
    @input = args.inputs
    @x = x
    @y = y
    @size = size
  end

  def offset
    [Constants::WIDTH/2 - @camera.x, Constants::HEIGHT/2 - @camera.y]
  end

  def width
    38 * @size
  end

  def height
    40 * @size
  end

  def draw
    offset_x, offset_y = offset
    @sprites << [@x + offset_x, @y + offset_y, 38 * @size, 40 * @size , Resources::SPR_SQUIRREL]
  end

  # unnecessary
  def test_move
    speed = 4
    direction_x = @input.keyboard.key_held.left ? -1 : (@input.keyboard.key_held.right ? 1 : 0)
    direction_y = @input.keyboard.key_held.down ? -1 : (@input.keyboard.key_held.up ? 1 : 0)
    @x += direction_x * speed
    @y += direction_y * speed
  end
end

def get_bark_spr(id)
  "sprites/bark_#{id}.png"
end

def create_tree
  width = Constants::TREE_WIDTH
  height = Constants::TREE_HEIGHT

  🌳 = []

  (0...width).each do |x|
    🌳[x] = []
    (0...height).each do |y|
      if x == 0
        🌳[x][y] = Tiles::BARK_LEFT
      elsif x == width - 1
        🌳[x][y] = Tiles::BARK_RIGHT
      else
        🌳[x][y] = Random.rand(10) == 1 ? Tiles::BARK_HOLE : Tiles::BARK
      end
    end
  end

  🌳
end

def cam_offset_x
  Constants::WIDTH/2 - @camera.x
end

def cam_offset_y
  Constants::HEIGHT/2 - @camera.y
end

def tick args
  @args = args
  @out = args.outputs
  @sprites = args.outputs.sprites
  @ticks = args.state.tick_count
  @labels = args.outputs.labels
  @input = args.inputs

  @camera ||= { x: Constants::WIDTH/2, y: Constants::HEIGHT/2}

  # args.outputs.labels  << [640, 500, 'Hello World!', 5, 1]
  # args.outputs.labels  << [640, 460, 'Go to docs/docs.html and read it!', 5, 1]
  # args.outputs.labels  << [640, 420, 'Join the Discord! http://discord.dragonruby.org', 5, 1]
  # args.outputs.sprites << [576, 280, 128, 101, 'dragonruby.png']
  @🌳 ||= create_tree
  @🐿 ||= Squirrel.new(@args,@camera,Constants::WIDTH/2,Constants::HEIGHT/2,3)

  @game_state ||= State::MENU

  case @game_state
  when State::MENU
    scene_menu
  when State::PLAYING
    scene_playing
  end

end

def draw_grass
  ground_scale = 4
  (0..4).each do |i|
    @sprites << [i * 64 * ground_scale + cam_offset_x, cam_offset_y, 64 * ground_scale, 64 * ground_scale, Resources::SPR_GROUND]
  end
end

def scene_menu
  squirrel_scale = 6
  text_scale = 6
  sin_scale = Math.sin(@ticks/10) * 15
  @sprites << [576, -60, 64 * squirrel_scale, 64 * squirrel_scale, Resources::SPR_SQUIRREL_FRONT]
  @sprites << [300, 120, 64 * text_scale + sin_scale, 64 * text_scale + sin_scale, Resources::SPR_MENU]

  draw_grass

  credits = ['A GGJ22 game by:','Kerstin','Laurin','Lea','Marcel']

  i = 0
  credits.each do |c|
    @labels << [Constants::WIDTH - 40, Constants::HEIGHT - 35 * i, c, 20, 2, 0, 0, 0, 255, Resources::FONT ]
    i += 1
  end

  #input

  if @input.keyboard.key_down.space
    @game_state = State::PLAYING
  end
end

def cam_follow_player
  offset = 50
  if @camera.x > @🐿.x + offset
    @camera.x = @🐿.x + offset
  elsif @camera.x < @🐿.x - offset
    @camera.x = @🐿.x - offset
  end

  if @camera.y > @🐿.y + offset
    @camera.y = @🐿.y + offset
  elsif @camera.y < @🐿.y - offset
    @camera.y = @🐿.y - offset
  end
end

def limit
  if @camera.y < Constants::HEIGHT/2
    @camera.y = Constants::HEIGHT/2
  end
end

def scene_playing

  @🐿.test_move
  cam_follow_player
  limit

  mid_offset = Constants::WIDTH / 2 - (Constants::TREE_WIDTH * Constants::TILE_SIZE) / 2
  # draw tree
  (0...Constants::TREE_WIDTH).each do |x|
    (0...Constants::TREE_HEIGHT).each do |y|
      @sprites << [x * Constants::TILE_SIZE + mid_offset + cam_offset_x,
                   y * Constants::TILE_SIZE + cam_offset_y,
                   Constants::TILE_SIZE,
                   Constants::TILE_SIZE,
                   get_bark_spr(@🌳[x][y])]
    end
  end

  @🐿.draw

  draw_grass

  # @camera.y += 0.3
end
