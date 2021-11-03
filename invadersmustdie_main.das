require daslib/media
require random
require strings

// options debugger            // uncomment for debug in VS Code
// require daslib/debug        // uncomment for debug in VS Code
let SCALE = 3
let WIDTH = 320*SCALE
let EXTENT = 60*SCALE
let HEIGHT = 240*SCALE
let ENEMIES_X = 11
let ENEMIES_Y = 5
let ENEMY_X_SPACING = 20*SCALE
let ENEMY_Y_SPACING = 20*SCALE
let ENEMIES = ENEMIES_X * ENEMIES_Y
let ENEMY_MOVE = 4
let MISSILE_DELAY = 2500.0
let LIVES = 3
var RAND_SEED = random_seed(42)
let UFO_INITIAL_DELAY = 5000.0
let UFO_MAX_DELAY = 5000.0
let UPDATE_TIME = 250.0
let LINE_HEIGHT = 12*SCALE

let green = make_color(90.0 / 255.0, 231.0 / 255.0, 49.0 / 255.0)
let cyan = make_color(74.0 / 255.0, 206.0 / 255.0, 222.0 / 255.0)
let magenta = make_color(239.0 / 255.0, 107.0 / 255.0, 255.0 / 255.0)
let yellow = make_color(188.0 / 255.0, 190.0 / 255.0, 0.0)
let red = make_color(181.0 / 255.0, 49.0 / 255.0, 32.0 / 255.0)

enum State
    Alive
    Hit
    Dead

enum GameState
    Game
    GameOver

var gameState = GameState GameOver

var lives: int = LIVES
struct Player
    pos: int4 = int4(WIDTH / 2, HEIGHT - 3 * SCALE, WIDTH / 2, HEIGHT - 3 * SCALE) // x,y: pos; z,w: prevpos
    img: Image <- create_image("player.png")
    speed: float = 0.3
    state: State = State Alive
    die: float = 600.0
    frame: int = 0

struct Projectile
    pos: int4    // x,y: pos; z,w: prevpos
    img: Image
    visible: bool
    speed: float = 0.2 // px/ms

struct Enemy
    pos: int4    // x,y: pos; z,w: prevpos
    img: array<Image>
    frame: int = 0
    state: State = State Alive
    color: uint
    die: float = 300.0
    pt: int

struct Missile
    pos: int4    // x,y: pos; z,w: prevpos
    img: array<Image>
    state: State = State Dead
    speed: float = 0.15 // px/ms
    frame: int = 0
    die: float = 300.0

struct Base
    pos:int4 = int4(0,0,0,0)
    tiles:int2[BASE_X * BASE_Y] = [[int2[BASE_X * BASE_Y] int2(0,0);int2(0,0);int2(0,0);int2(0,0);int2(0,0);int2(0,0);int2(0,0);int2(0,0);int2(0,0)]]

struct Ufo
    pos:int4 = int4(0,0,0,0)
    img: Image
    state: State = State Dead
    speed: float = 0.1 // px/ms
    frame: int = 0
    die: float = 300.0
    color: uint
    pt: int


let BASE_X = 3
let BASE_Y = 3


var base0: Base
var base1: Base
var base2: Base
var base3: Base

var frameTime: float = 250.0
var frameTimeDec: float = 6.0
var update: float = frameTime
var player <- Player()
var projectile <- Projectile()
var enemies: array<Enemy>
var missiles: array<Missile>
var ufo: Ufo
var missile_index = 0
var missile_delay = 0.0
let missileUpdateTime: float = 60.0
var missileUpdate: float = missileUpdateTime
var ufo_delay = 0.0
var win = ENEMIES
var pt = 0
var round = 0
var d = -ENEMY_MOVE * SCALE
var dir = [[int[ENEMIES_Y] d; d; d; d; d]]

let invaderSnd : array<PcmSound> <- to_array_move([[PcmSound[] create_sound("fastinvader4.wav"); create_sound("fastinvader1.wav"); create_sound("fastinvader2.wav"); create_sound("fastinvader3.wav")]])
var invaderSndIdx = 0
let ufoSnd <- create_sound("ufo_lowpitch.wav")
var ufoSndHandle: PlayingSoundHandle
var ufoSndPlaying = false
let killedSnd <- create_sound("explosion.wav")
let shootSnd <- create_sound("invaderkilled.wav")
let invaderDiedSnd <- create_sound("shoot.wav")
let invadersMustDie <- create_sound("invadersmustdie.wav")

let hit <- create_image("hit.png")
let enemy1 : array<Image> <- to_array_move([[Image[2] create_image("enemy1_1.png"); create_image("enemy1_2.png") ]])
let enemy2 : array<Image> <- to_array_move([[Image[2] create_image("enemy2_1.png"); create_image("enemy2_2.png") ]])
let enemy3 : array<Image> <- to_array_move([[Image[2] create_image("enemy3_1.png"); create_image("enemy3_2.png") ]])
let enemy4 : array<Image> <- to_array_move([[Image[2] create_image("enemy4_1.png"); create_image("enemy4_2.png") ]])
let missile1 : array<Image> <- to_array_move([[Image[4] create_image("missile1_1.png"); create_image("missile1_2.png"); create_image("missile1_1.png"); create_image("missile1_4.png")]])
let missile2 : array<Image> <- to_array_move([[Image[4] create_image("missile2_1.png"); create_image("missile2_2.png"); create_image("missile2_3.png"); create_image("missile2_4.png")]])
let missile3 : array<Image> <- to_array_move([[Image[4] create_image("missile3_1.png"); create_image("missile3_2.png"); create_image("missile2_3.png"); create_image("missile3_4.png")]])
var tile0_0: array<Image> <- to_array_move([[Image[5] create_image("tile1.png"); create_image("tile1_1.png"); create_image("tile1_2.png"); create_image("tile1_3.png"); create_image("tile1_4.png")]])
var tile0_1: array<Image> <- to_array_move([[Image[4] create_image("tile1_1_1.png"); create_image("tile1_1_2.png"); create_image("tile1_1_3.png"); create_image("tile1_1_4.png")]])
var tile0_2: array<Image> <- to_array_move([[Image[3] create_image("tile1_1_1_1.png"); create_image("tile1_1_1_2.png"); create_image("tile1_1_1_3.png")]])
var tile0_3: array<Image> <- to_array_move([[Image[2] create_image("tile1_1_1_1_1.png"); create_image("tile1_1_1_1_2.png")]])
var tile0_4: array<Image> <- to_array_move([[Image[1] create_image("tile1_1_1_1_1_1.png")]])
var tile0: array<array<Image>> <- [{auto tile0_0; tile0_1; tile0_2; tile0_3; tile0_4}]
var tile1_0: array<Image> <- to_array_move([[Image[3] create_image("tile2.png"); create_image("tile2_1.png"); create_image("tile2_2.png")]])
var tile1_1: array<Image> <- to_array_move([[Image[2] create_image("tile2_1_1.png"); create_image("tile2_1_2.png")]])
var tile1_2: array<Image> <- to_array_move([[Image[1] create_image("tile2_1_1_1.png")]])
var tile1: array<array<Image>> <- [{auto tile1_0; tile1_1; tile1_2}]
var tile2_0: array<Image> <- to_array_move([[Image[3] create_image("tile4.png"); create_image("tile4_1.png"); create_image("tile4_2.png")]])
var tile2_1: array<Image> <- to_array_move([[Image[2] create_image("tile4_1_1.png"); create_image("tile4_1_2.png")]])
var tile2_2: array<Image> <- to_array_move([[Image[1] create_image("tile4_1_1_1.png")]])
var tile2: array<array<Image>> <- [{auto tile2_0; tile2_1; tile2_2}]
var tile3_0: array<Image> <- to_array_move([[Image[1] create_image("tile3.png")]])
var tile3: array<array<Image>> <- [{auto tile3_0}]
//let tiles: array<array<array<Image>>> <- [{auto tile1; tile0; tile2; tile0; tile0; tile0; tile0; tile3; tile0}]
var tiles: array<array<Image>>[BASE_X * BASE_Y]
let ufo1 <- create_image("ufo1.png")
let ufo2 <- create_image("ufo2.png")
let ufo_crash : array<Image> <- to_array_move([[Image[2] create_image("ufo_crash1.png"); create_image("ufo_crash2.png") ]])

let missile_hit <- create_image("missile_hit.png")
let player_hit : array<Image> <- to_array_move([[Image[2] create_image("player_hit1.png"); create_image("player_hit2.png") ]])

def setupBases
    let Y = HEIGHT - 120
    let X = WIDTH / 5
    base0 <- Base()
    base0.pos.x = X
    base0.pos.z = base0.pos.x
    base0.pos.y = Y
    base0.pos.w = base0.pos.y
    base1 <- Base()
    base1.pos.x = X + X
    base1.pos.z = base1.pos.x
    base1.pos.y = Y
    base1.pos.w = base1.pos.y
    base2 <- Base()
    base2.pos.x = X + X + X
    base2.pos.z = base2.pos.x
    base2.pos.y = Y
    base2.pos.w = base2.pos.y
    base3 <- Base()
    base3.pos.x = X + X + X + X
    base3.pos.z = base3.pos.x
    base3.pos.y = Y
    base3.pos.w = base3.pos.y
    tiles[0] := tile1
    tiles[1] := tile0
    tiles[2] := tile2
    tiles[3] := tile0
    tiles[4] := tile0
    tiles[5] := tile0
    tiles[6] := tile0
    tiles[7] := tile3
    tiles[8] := tile0
    //<- [{auto tile1; tile0; tile2; tile0; tile0; tile0; tile0; tile3; tile0}]

def rect(pos:int4&; img:Image&)
    return int4(min(pos.x, pos.z) - img.width * SCALE / 2, min(pos.y, pos.w) - img.height * SCALE / 2, max(pos.x, pos.z) + img.width * SCALE / 2, max(pos.y, pos.w) + img.height * SCALE / 2)

def hit(rect1:int4; rect2:int4)
    return rect1.x < rect2.z && rect1.z > rect2.x && rect1.y < rect2.w && rect1.w > rect2.y


def drawImage(var pos:int2; img:Image&)
    pos.x -= img.width / 2 * SCALE
    pos.y -= img.height / 2 * SCALE
    draw_image(img, pos.x, pos.y, make_color(1.0), int2(img.width * SCALE, img.height * SCALE))

def drawBase(base:Base&)
    var pos = base.pos.xy
    pos.x -= tiles[0][0][0].width * SCALE
    pos.y -= tiles[0][0][0].height * SCALE
    for i in range(BASE_X * BASE_Y)
        if base.tiles[i].x >= 0 && base.tiles[i].y >= 0
            drawImage(pos, tiles[i][base.tiles[i].x][base.tiles[i].y])
        pos.x += tiles[0][0][0].width * SCALE
        if (i + 1) % BASE_X == 0
            pos.x = base.pos.x
            pos.x -= tiles[0][0][0].width * SCALE
            pos.y += tiles[0][0][0].height * SCALE

def baseHit(rect1:int4; var base:Base&; up:bool; clear:bool)
    var rect2: int4 = int4(base.pos.x - tiles[0][0][0].width / 2 * SCALE * BASE_X, base.pos.y - tiles[0][0][0].height / 2 * SCALE * BASE_Y, base.pos.x + tiles[0][0][0].width  / 2 * SCALE * BASE_X, base.pos.y + tiles[0][0][0].height / 2 * SCALE * BASE_Y)
    if !hit(rect1, rect2)
        return false
    var pos = base.pos.xy
    pos.x -= tiles[0][0][0].width * SCALE
    pos.y -= tiles[0][0][0].height * SCALE
    var i:int
    var end:int
    var dir:int
    if up
        i = 0
        end = BASE_X * BASE_Y
        dir = 1
    else
        i = BASE_X * BASE_Y - 1
        end = -1
        dir = -1
    let w = tiles[0][0][0].width * SCALE
    let h = tiles[0][0][0].height * SCALE
    let w2 = tiles[0][0][0].width / 2* SCALE
    let h2 = tiles[0][0][0].height / 2 * SCALE
    let rects : int4[BASE_X * BASE_Y] = [[int4[BASE_X * BASE_Y]
        int4(base.pos.x - w - w2,
            base.pos.y - h - h2,
            base.pos.x - w + w2,
            base.pos.y - h + h2);
        int4(base.pos.x - w2,
            base.pos.y - h - h2,
            base.pos.x + w2,
            base.pos.y - h + h2);
        int4(base.pos.x + w - w2,
            base.pos.y - h - h2,
            base.pos.x + w + w2,
            base.pos.y - h + h2);

        int4(base.pos.x - w - w2,
            base.pos.y - h2,
            base.pos.x - w + w2,
            base.pos.y + h2);
        int4(base.pos.x - w2,
            base.pos.y - h2,
            base.pos.x + w2,
            base.pos.y + h2);
        int4(base.pos.x + w - w2,
            base.pos.y - h2,
            base.pos.x + w + w2,
            base.pos.y + h2);

        int4(base.pos.x - w - w2,
            base.pos.y + h - h2,
            base.pos.x - w + w2,
            base.pos.y + h + h2);
        int4(base.pos.x - w2,
            base.pos.y + h - h2,
            base.pos.x + w2,
            base.pos.y + h + h2);
        int4(base.pos.x + w - w2,
            base.pos.y + h - h2,
            base.pos.x + w + w2,
            base.pos.y + h + h2)]]
    while i != end
        if base.tiles[i].x < 0 || base.tiles[i].y < 0
            i += dir
            continue
        if hit(rects[i], rect1)
            if clear
                base.tiles[i].xy = int2(-1, -1)
            elif up
                base.tiles[i].y += 1
                if base.tiles[i].y >= length(tiles[i])
                    base.tiles[i].y = -1
            else
                base.tiles[i].x += 1
                if base.tiles[i].x >= length(tiles[i][base.tiles[i].y])
                    base.tiles[i].x = -1
            return true
        i += dir
    return false

def setupUfo
    if ufoSndPlaying
        stop_sound(ufoSndHandle)
        ufoSndPlaying = false
    ufo <- Ufo()
    ufo_delay = UFO_INITIAL_DELAY + random_float(RAND_SEED) * UFO_MAX_DELAY
    if random_int(RAND_SEED) % 2 == 0
        ufo.img := ufo1
        ufo.pt = 100
    else
        ufo.img := ufo2
        ufo.pt = 500
    if random_int(RAND_SEED) % 2 == 0
        ufo.color = magenta
    else
        ufo.color = red
    ufo.pos.x = ufo.img.width / 2 * SCALE
    ufo.pos.z = ufo.pos.X
    ufo.pos.y = 12 * SCALE
    ufo.pos.w = ufo.pos.y

var updateLine = 0
var updateY = 0

// 'initialize' runs once when game starts and every hot-reload
[export]
def initialize
    set_font_name("ARCADECLASSIC.TTF")
    set_font_size(LINE_HEIGHT)
    invaderSndIdx = 0
    win = ENEMIES
    frameTime = UPDATE_TIME
    update = frameTime
    ufoSndPlaying = false
    set_window_title("InvadersMustDie")
    set_resolution(WIDTH + EXTENT, HEIGHT)
    projectile.img <- create_image("projectile.png")
    updateY = 0
    var missile <- Missile()
    missile.img := missile1
    emplace(missiles, missile)
    missile <- Missile()
    missile.img := missile2
    emplace(missiles, missile)
    missile <- Missile()
    missile.img := missile3
    emplace(missiles, missile)
    missile_delay = random_float(RAND_SEED) * MISSILE_DELAY
    setupUfo()
    var startX, startY = 15*SCALE
    clear(enemies)
    for i in range(0, ENEMIES)
        var enemy <- Enemy()
        if i < ENEMIES_X
            enemy.color = green
            enemy.img := enemy3
            enemy.pt = 30
        elif i < ENEMIES_X * 3
            enemy.color = cyan
            enemy.img := enemy2
            enemy.pt = 20
        elif i < ENEMIES
            enemy.color = magenta
            enemy.img := enemy1
            enemy.pt = 10
        if i % ENEMIES_X == 0
            startX = (WIDTH  - ENEMIES_X * ENEMY_X_SPACING + ENEMY_X_SPACING) / 2
            startY += ENEMY_Y_SPACING
        enemy.pos.x = startX - enemy.img[0].width / 2
        enemy.pos.y = startY - enemy.img[0].height / 2
        startX += ENEMY_X_SPACING
        emplace(enemies, enemy)
    setupBases()
    play_sound(invadersMustDie)
    return

// this function is called to update game data,
// dt - time elapsed since the previous update (in seconds)
[export]
def act(var dt: float)
    dt *= 1000.0
    if player.state == State Dead
        player <- Player()
        --lives
        if lives < 0
            gameState = GameState GameOver
            lives = LIVES
            round = 0
            pt = 0
    if win <= 0
        ++round
        initialize()
    elif gameState == GameState GameOver
        if get_key(VK_SPACE)
            gameState = GameState Game
            initialize()
        return
    for enemy in enemies
        enemy.pos.z = enemy.pos.x
        enemy.pos.w = enemy.pos.y
    player.pos.z = player.pos.x
    if get_key(VK_ESCAPE)
        schedule_quit_game()
    elif get_key(VK_LEFT)
        if player.state == State Alive
            player.pos.z = player.pos.x
            player.pos.x = max(player.img.width / 2 * SCALE,  player.pos.x - int(player.speed * dt))
    elif get_key(VK_RIGHT)
        if player.state == State Alive
            player.pos.z = player.pos.x
            player.pos.x = min(WIDTH - player.img.width / 2 * SCALE,  player.pos.x + int(player.speed * dt))
    elif get_key(VK_SPACE)
        if !projectile.visible && player.state == State Alive
            shootSnd |> play_sound()
            projectile.visible = true
            projectile.pos.x = player.pos.x
            projectile.pos.z = player.pos.x
            projectile.pos.y = player.pos.y - (player.img.height + projectile.img.height) * SCALE
            projectile.pos.w = projectile.pos.y
    if projectile.visible
        projectile.pos.w = projectile.pos.y
        var hit = baseHit(rect(projectile.pos, projectile.img), base0, false, false)
        hit ||= baseHit(rect(projectile.pos, projectile.img), base1, false, false)
        hit ||= baseHit(rect(projectile.pos, projectile.img), base2, false, false)
        hit ||= baseHit(rect(projectile.pos, projectile.img), base3, false, false)
        projectile.pos.y -= int(projectile.speed * dt * float(SCALE))
        if projectile.pos.y < 0 || hit
            projectile.visible = false

    var missile& = missiles[missile_index]
    if missile.state == State Alive
        missile.pos.w = missile.pos.y
        var hit = baseHit(rect(missile.pos, missile.img[0]), base0, true, false)
        hit ||= baseHit(rect(missile.pos, missile.img[0]), base1, true, false)
        hit ||= baseHit(rect(missile.pos, missile.img[0]), base2, true, false)
        hit ||= baseHit(rect(missile.pos, missile.img[0]), base3, true, false)
        if hit
            missile.state = State Hit
        else
            missile.pos.y += int(missile.speed * dt * float(SCALE))
            if missile.pos.y + missile.img[0].height / 2 * SCALE >= HEIGHT
                missile.state = State Hit
            elif player.state == State Alive && hit(rect(missile.pos, missile.img[0]), rect(player.pos, player.img))
                missile.state = State Dead
                player.state = State Hit
            elif projectile.visible && hit(rect(missile.pos, missile.img[0]), rect(projectile.pos, projectile.img))
                missile.state = State Hit
                projectile.visible = false
    if missile.state == State Hit
        missile.die -= dt
        if missile.die < 0.0
            missile.state = State Dead
            missile_delay = random_float(RAND_SEED) * MISSILE_DELAY
    if missile_delay < 0.0 && missile.state == State Dead
        missile_index = random_int(RAND_SEED) % length(missiles)
        var miss& = missiles[missile_index]
        miss <- Missile()
        if missile_index == 0
            miss.img := missile1
        elif missile_index == 1
            miss.img := missile2
        else
            miss.img := missile3
        var x = random_int(RAND_SEED) % ENEMIES_X
        x += (ENEMIES_Y - 1) * ENEMIES_X
        while x > 0
            if enemies[x].state == State Alive
                break
            x -= ENEMIES_X
        if x > 0
            miss.state = State Alive
            miss.pos = enemies[x].pos;
            miss.pos.y = enemies[x].pos.y + enemies[x].img[0].height / 2 * SCALE
            miss.pos.zw = miss.pos.xy
    missile_delay -= dt

    if player.state == State Hit
        player.die -= dt
        if player.die < 0.0
            player.state = State Dead

    if missileUpdate < 0.0 && missile.state == State Alive
        missile.frame = (missile.frame + 1) % length(missile.img)

    if update < 0.0
        play_sound(invaderSnd[invaderSndIdx])
        invaderSndIdx = (invaderSndIdx + 1) % length(invaderSnd)
        if player.state == State Hit
            player.frame = (player.frame + 1) % length(player_hit)
        if ufo.state == State Hit
            ufo.frame = (ufo.frame + 1) % length(ufo_crash)
        var minX = WIDTH
        var maxX = 0
        for x in range(ENEMIES_X)
            var enemy& = enemies[updateLine * ENEMIES_X + x]
            enemy.frame = (enemy.frame + 1) % length(enemy.img)
            if enemy.state == State Alive
                minX = min(minX, enemy.pos.x)
                maxX = max(maxX, enemy.pos.x)
        if minX + dir[updateLine] - enemy1[0].width * SCALE / 2 <= 0 || maxX + dir[updateLine] + enemy1[0].width * SCALE / 2 >= WIDTH
            d = -d
            for i in range(length(dir))
                dir[i] = -dir[i]
            updateY = 1
        for x in range(ENEMIES_X)
            let d = dir[updateLine]
            var enemy& = enemies[updateLine * ENEMIES_X + x]
            enemy.pos.z = enemy.pos.x
            enemy.pos.x += d
            if enemy.state == State Alive
                baseHit(rect(enemy.pos, enemy.img[0]), base0, true, true)
                baseHit(rect(enemy.pos, enemy.img[0]), base1, true, true)
                baseHit(rect(enemy.pos, enemy.img[0]), base2, true, true)
                baseHit(rect(enemy.pos, enemy.img[0]), base3, true, true)
        updateLine = (updateLine + 1) % length(dir)
        if updateY == 1
            updateY = 0
            var i = ENEMIES - 1
            while i >= 0
                var enemy& = enemies[i]
                if enemy.state == State Alive &&  enemy.pos.y + ENEMY_MOVE * SCALE + enemy.img[0].height / 2 * SCALE >= HEIGHT
                    player.state = State Dead
                    break
                enemy.pos.y += ENEMY_MOVE * SCALE
                enemy.pos.w = enemy.pos.y
                if enemy.pos.y >= HEIGHT / 2
                    enemy.color = yellow
                elif  enemy.pos.y >= HEIGHT * 2 / 3
                    enemy.color = red
                --i

    var i = ENEMIES - 1
    while i >= 0
        var enemy& = enemies[i]
        if enemy.state == State Alive
            if projectile.visible && hit(rect(enemy.pos, enemy.img[0]), rect(projectile.pos, projectile.img))
                enemy.state = State Hit
                projectile.visible = false
                play_sound(invaderDiedSnd)
            elif player.state == State Alive && hit(rect(enemy.pos, enemy.img[0]), rect(player.pos, player.img))
                player.state = State Hit
                enemy.state = State Dead
        if enemy.state == State Hit
            enemy.die -= dt
            if enemy.die < 0.0
                pt += enemy.pt
                enemy.state = State Dead
                --win
                frameTime -= frameTimeDec
        --i

    if missile.state == State Alive
        if projectile.visible && hit(rect(missile.pos, missile.img[0]), rect(projectile.pos, projectile.img))
            projectile.visible = false
            missile.state = State Hit
        if player.state == State Alive && hit(rect(missile.pos, missile.img[0]), rect(player.pos, player.img))
            play_sound(killedSnd)
            player.state = State Hit
            missile.state = State Dead

    if ufo.state == State Alive
        ufo.pos.z = ufo.pos.x
        ufo.pos.x += int(ufo.speed * dt * float(SCALE))
        if ufo.pos.x + missile.img[0].width / 2 * SCALE >= WIDTH
            ufo.state = State Dead
            setupUfo()
        elif projectile.visible && hit(rect(ufo.pos, ufo.img), rect(projectile.pos, projectile.img))
            play_sound(killedSnd)
            ufo.state = State Hit
            projectile.visible = false
    elif ufo.state == State Dead && ufo_delay < 0.0
        ufo.state = State Alive
        ufoSndHandle = play_sound_loop(ufoSnd)
        ufoSndPlaying = true
    elif ufo.state == State Hit
        ufo.die -= dt
        if ufo.die < 0.0
            pt += ufo.pt
            ufo.state = State Dead
            setupUfo()
    elif ufo_delay < 0.0 && ufo.state == State Dead
        setupUfo()
    ufo_delay -= dt

    if update < 0.0
        update += frameTime
    update -= dt
    if missileUpdate < 0.0
        missileUpdate += missileUpdateTime
    missileUpdate -= dt
    return

// this function will be called every frame after 'act',
// you can draw anything in this function
[export]
def draw
    var START = 20
    text_out(WIDTH, START, "HIGH", 0xffffffff)
    text_out(WIDTH + 10 * SCALE, START + LINE_HEIGHT, "SCORE", 0xffffffff)
    text_out(WIDTH + 10 * SCALE, START + LINE_HEIGHT + LINE_HEIGHT, format("%05d",pt), 0xffffffff)
    START = HEIGHT / 2
    text_out(WIDTH, START, "ROUND", 0xffffffff)
    text_out(WIDTH + 20 * SCALE, START + LINE_HEIGHT, format("%d",round), 0xffffffff)
    if gameState == GameState GameOver
        START = 40
        var len = get_text_size("INVADERS")
        text_out(int(WIDTH - int(len.x)) / 2, START, "INVADERS", green)
        len = get_text_size("MUST")
        text_out(int(WIDTH - int(len.x)) / 2, START + LINE_HEIGHT, "MUST", cyan)
        len = get_text_size("DIE")
        text_out(int(WIDTH - int(len.x)) / 2, START + LINE_HEIGHT + LINE_HEIGHT, "DIE", red)
        len = get_text_size("SCORE   ADVANCE   TABLE")
        START = HEIGHT / 3
        text_out(int(WIDTH - int(len.x)) / 2, START, "SCORE   ADVANCE   TABLE", red)
        START += LINE_HEIGHT + LINE_HEIGHT
        let w = 400
        text_out(w, START, "   MYSTERY", red)
        draw_image(ufo.img, w - ufo.img.width * SCALE, START + ufo.img.height, red, int2(ufo.img.width * SCALE, ufo.img.height * SCALE))
        START += LINE_HEIGHT
        text_out(w, START, "   30   POINTS", green)
        draw_image(enemy3[0], w - enemy3[0].width * SCALE, START + enemy3[0].height, green, int2(enemy3[0].width * SCALE, enemy3[0].height * SCALE))
        START += LINE_HEIGHT
        text_out(w, START, "   20   POINTS", green)
        draw_image(enemy2[0], w - enemy2[0].width * SCALE, START + enemy2[0].height, green, int2(enemy2[0].width * SCALE, enemy2[0].
        height * SCALE))
        START += LINE_HEIGHT
        text_out(w, START, "   10   POINTS", cyan)
        draw_image(enemy1[0], w - enemy1[0].width * SCALE, START + enemy2[0].height, cyan, int2(enemy1[0].width * SCALE, enemy1[0].
        height * SCALE))

        len = get_text_size("PRESS   SPACE")
        START = HEIGHT * 3 / 4
        text_out(int(WIDTH - int(len.x)) / 2, START, "PRESS   SPACE", 0xffffffff)
        len = get_text_size("GAIJIN   DISTRIBUTION   KFT.")
        START = HEIGHT * 7 / 8
        text_out(int(WIDTH - int(len.x)) / 2, START, "GAIJIN   DISTRIBUTION   KFT", 0xffffffff)
        return
    var d = EXTENT / 4
    for i in range(0, lives)
        draw_image(player.img, WIDTH + d - player.img.width / 2 * SCALE, HEIGHT - 10 * SCALE, make_color(1.0), int2(player.img.width * SCALE, player.img.height * SCALE))
        d += EXTENT / 4
    if player.state == State Alive
        draw_image(player.img, player.pos.x - player.img.width / 2 * SCALE, player.pos.y - player.img.height * SCALE, make_color(1.0), int2(player.img.width * SCALE, player.img.height * SCALE))
    elif player.state == State Hit
        let img& = player_hit[player.frame]
        draw_image(img, player.pos.x - img.width / 2 * SCALE, player.pos.y - img.height * SCALE, make_color(1.0), int2(img.width * SCALE, img.height * SCALE))
    if projectile.visible
        draw_image(projectile.img, projectile.pos.x - projectile.img.width / 2 * SCALE, projectile.pos.y - projectile.img.height * SCALE, make_color(1.0), int2(projectile.img.width * SCALE, projectile.img.height * SCALE))
    let missile& = missiles[missile_index]
    if missile.state == State Alive
        let img& = missile.img[missile.frame]
        draw_image(img, missile.pos.x - img.width / 2 * SCALE, missile.pos.y - img.height * SCALE, make_color(1.0), int2(img.width * SCALE, img.height * SCALE))
    elif missile.state == State Hit
        let img& = missile_hit
        draw_image(img, missile.pos.x - img.width / 2 * SCALE, missile.pos.y - img.height * SCALE, make_color(1.0), int2(img.width * SCALE, img.height * SCALE))
    for enemy in enemies
        if enemy.state == State Alive
            let img& = enemy.img[enemy.frame]
            draw_image(img, enemy.pos.x - img.width / 2 * SCALE, enemy.pos.y - img.height * SCALE, enemy.color, int2(img.width * SCALE, img.height * SCALE))
        elif enemy.state == State Hit
            let img& = hit
            draw_image(img, enemy.pos.x - img.width / 2 * SCALE, enemy.pos.y - img.height * SCALE, enemy.color, int2(img.width * SCALE, img.height * SCALE))
    if ufo.state == State Alive
        draw_image(ufo.img, ufo.pos.x - ufo.img.width / 2 * SCALE, ufo.pos.y - ufo.img.height * SCALE, ufo.color, int2(ufo.img.width * SCALE, ufo.img.height * SCALE))
    elif ufo.state == State Hit
        let img& = ufo_crash[ufo.frame]
        draw_image(img, ufo.pos.x - img.width / 2 * SCALE, ufo.pos.y - img.height * SCALE, ufo.color, int2(img.width * SCALE, img.height * SCALE))
    drawBase(base0)
    drawBase(base1)
    drawBase(base2)
    drawBase(base3)
    return

options debugger
require daslib/debug
