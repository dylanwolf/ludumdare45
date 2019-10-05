pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- configuration --------------
min_x = 48

player = {}
difficulty = {}

gamestates = {
  spaceman = 0,
  in_ship = 1,
  gameover = 2
}

weaponids = {
  basic = 1,
  laser = 2,
  missile = 3
}

shake = {
  timer = 0,
  max_timer = 10,
  max_amount = 3
}

function reset_game()
  difficulty.kills = 0
  difficulty.enemy_timer = 60
  difficulty.max_enemy_life = 3

  player.score = 0
  player.x = 64
  player.y = 100
  player.state = gamestates.spaceman
  player.sprite = 1
  player.shields = nil
  player.weapon = {
    rate = 25,
    sprite = 33,
    damage = 1,
    width = 4,
    height = 4,
    update_method = weapon_basic,
    id = weaponids.basic,
    exp = 0,
    fire = false
  }
  player.shoot_timer = 0
  
  enemies = {}
  powerups = {}
  bullets = {}
end

fire_anim_timer = {
  frame = 1,
  timer = 0,
  max_timer = 5
}

fire_anim = {
	 { 12, 13 },
	 { 12, 13, 14, 15 }
}

enemy_time = 0

enemies = {}
bullets = {}
powerups = {}
--------------------------------

-- life cycle ------------------
function _init()
  reset_game()
  palt(0, false)
  palt(4, true)
end

function _update60()
  handle_input()
  for en in all(enemies) do
    update_enemy(en)
  end
  for bl in all(bullets) do
    update_bullet(bl)
  end
  for pwr in all(powerups) do
    update_powerup(pwr)
  end
  detect_collisions()
  cleanup_list(enemies)
  cleanup_list(bullets)
  cleanup_list(powerups)
  spawn_enemy()
end

function _draw()
  cls()
  screen_shake()
 
  draw_player()
  for en in all(enemies) do
    draw_enemy(en)
  end
  for bl in all(bullets) do
    draw_bullet(bl)
  end
  for pwr in all(powerups) do
    draw_powerup(pwr)
  end

  draw_ui()
  --debug_info()
end
--------------------------------

-- helper methods --------------
function debug_info()
  print("enemies: " .. #enemies ..
    ", kills: " .. difficulty.kills ..
    ", bullets: " .. #bullets,
    0, 0)
  print("shields: " ..
    (player.shields == nil and
      "(none)" or player.shields),
    0, 8)
  print("weapon: " ..
    player.weapon.id ..
    ", exp: " ..
    player.weapon.exp,
    0, 16)
end

function draw_tile(sprite, col, row)
  spr(sprite,
    col * 8,
    row * 8)
end

function rnd_bool()
  if rnd(2) >= 1 then
    return true
  end
  return false
end

function update_animation(
  anim_state, anim_frames)
  
  anim_state.timer -= 1
  
  if anim_state.timer <= 0 then
    anim_state.frame += 1
    anim_state.timer =
      anim_state.max_timer
  end
  
  if anim_state.frame >
    #anim_frames then
    anim_state.frame = 1
  end
end

function collide(x1, y1, w1, h1,
  x2, y2, w2, h2)
  
  return (
    (
      (x1 >= x2 and x1 <= x2+w2) or
      (x2 >= x1 and x2 <= x1+w1)
    ) and
    (
      (y1 >= y2 and y1 <= y2+h2) or
      (y2 >= y1 and y2 <= y1+h1)
    )
  )
end

function cleanup_list(lst)
  i = 1
  while i <= #lst do
    if lst[i].delete then
      del(lst, lst[i])
    else
      i += 1
    end
  end
end

function screen_shake()
  if shake.timer > 0 then
    camera(
      rnd(shake.max_amount*2)-shake.max_amount,
      rnd(shake.max_amount*2)-shake.max_amount)
    shake.timer -= 1
  elseif shake.timer == 0 then
    camera(0, 0)
    shake.timer = -1
  end
end
--------------------------------

-- weapon behaviors ------------
function weapon_basic(bl)
  bl.y -= 1
end

function weapon_laser(bl)
  bl.y -= 2
end
--------------------------------

-- powerup behaviors -----------
function shield_powerup()
  if player.shields == nil then
    player.shields = 1
  else
    player.shields += 1
  end
end

function laser_powerup()
  if player.weapon.id != 
    weaponids.laser then
    player.weapon.rate = 20
    player.weapon.sprite = 34
    player.weapon.damage = 1
    player.weapon.width = 4
    player.weapon.height = 8
    player.weapon.exp = 0
    player.weapon.fire = false
    player.weapon.update_method =
      weapon_laser
    player.weapon.id =
      weaponids.laser
  else
    player.weapon.exp += 1
    if player.weapon.exp >= 4 then
      player.weapon.rate = 8
    elseif player.weapon.exp >= 3 then
      player.weapon.rate = 11
    elseif player.weapon.exp >= 2 then
      player.weapon.rate = 14
    elseif player.weapon.exp >= 1 then
      player.weapon.rate = 17
    end
  end
end

function missile_powerup()
  if player.weapon.id !=
    weaponids.missile then
    player.weapon.id = weaponids.missile
    player.weapon.rate = 45
    player.weapon.sprite = 35
    player.weapon.damage = 3
    player.weapon.fire = true
    player.weapon.width = 8
    player.weapon.height = 8
    player.weapon.exp = 0
    player.weapon.update_method =
      weapon_basic
  else
    player.weapon.exp += 1
    if player.weapon.exp >= 4 then
      player.weapon.damage = 10
      player.weapon.rate = 25
    elseif player.weapon.exp >= 3 then
      player.weapon.damage = 7
      player.weapon.rate = 30
    elseif player.weapon.exp >= 2 then
      player.weapon.damage = 5
      player.weapon.rate = 30
    elseif player.weapon.exp >= 1 then
      player.weapon.damage = 5
      player.weapon.rate = 40
    end
  end
end
--------------------------------

-- player functions ------------
function handle_input()
  if player.state == 
    gamestates.gameover then
    if btnp(4) or btnp(5) then
      reset_game()
    end
    return
  end

  if btn(0) then
    player.x -= 1
  end
  if btn(1) then
    player.x += 1
  end
  if btn(2) then
    player.y -= 1
  end
  if btn(3) then
    player.y += 1
  end
  
  if player.state > 
    gamestates.spaceman then
    player.shoot_timer -= 1
    if player.shoot_timer < 0 and
      (btn(4) or btn(5)) then
      
      bl = {
        x = player.x,
        y = player.y - 4,
        sprite = player.weapon.sprite,
        delete = false,
        damage = player.weapon.damage,
        update = player.weapon.update_method,
        width = player.weapon.width,
        height = player.weapon.height,
        fire = player.weapon.fire and {
          frame = 1,
          timer = 0,
          max_timer =5
        } or nil
      }
      add(bullets, bl)
      player.shoot_timer =
        player.weapon.rate  
    end
  end
  
  player.x = mid(min_x, player.x, 120)
  player.y = mid(0, player.y, 120)
end

function draw_player()
  spr(player.sprite,
    player.x, player.y)
  draw_player_fire()
  if player.shields != nil and
    player.shields > 0 then
    draw_shields(player.x,
      player.y,
      false, player.shields)
  end
end

shield_colors = {5,6,7,15,10,9}

function draw_shields(x, y, flipy, amt)
  if amt > 0 then
    idx = mid(1, amt, #shield_colors)
    pal(10, shield_colors[idx])
  
    spr(20, x, y, 1, 1, false, flipy)
    pal(10, 10)
  end
end

function draw_player_fire()
  anim = fire_anim[1]
  if player.sprite > 1 then
    anim = fire_anim[2]
  end

  update_animation(fire_anim_timer,
    anim)
    
   spr(anim[fire_anim_timer.frame],
     player.x, player.y+8)
end

function update_bullet(bl)
  bl.update(bl)
  if bl.y < 0 then
    bl.delete = true
  end
  if bl.fire != nil then
    update_animation(bl.fire,
      fire_anim[1])
  end
end

function draw_bullet(bl)
  spr(bl.sprite, bl.x, bl.y)
  if bl.fire != nil then
    spr(fire_anim[1][bl.fire.frame],
      bl.x, bl.y + 8)
  end
end
--------------------------------

-- enemy functions -------------
function spawn_enemy()
  enemy_time -= 1
  if enemy_time <= 0 then
     enemy = {
       x = rnd(128-min_x) + min_x,
       y = 0,
       life = ceil(
         rnd(difficulty.max_enemy_life)),
       fire = {
         frame = 1,
         timer = 0,
         max_timer = 5
       },
       delete = false
     }
     
     enemy_time =
       difficulty.enemy_timer
     add(enemies, enemy)
  end
end

function update_enemy(en)
  en.y += 1
  if en.y > 128 then
    en.delete = true
  end
end

function draw_enemy(en)
  sprite = 17
  if player.state >
    gamestates.spaceman then
    sprite = 19
  end

  spr(sprite, en.x, en.y)
  update_animation(en.fire,
    fire_anim[2])
  spr(fire_anim[2][en.fire.frame],
    en.x, en.y-8, 1, 1, false,
    true)
  if player.state >
    gamestates.spaceman and
    en.life > 1 then
    draw_shields(en.x, en.y,
      true, en.life - 1)
  end  
end

function handle_player_collide()
  if player.state ==
    gamestates.spaceman then
    player.state = gamestates.in_ship
    player.sprite = 18
  elseif player.shields == nil then
    player.state = gamestates.gameover
    shake.timer = shake.max_timer
    -- todo: spawn explosion
  else
    player.shields -= 1
    shake.timer = shake.max_timer
    if player.shields < 0 then
      player.state = gamestates.gameover
      shake.timer = shake.max_timer
      -- todo: spawn explosion
    end
  end
end

function handle_bullet_collide(bl, en)
  en.life -= bl.damage  
  bl.delete = true
  player.score += 10 * mid(1, bl.damage, en.life)

  if en.life <= 0 then
    player.score += 100
    en.delete = true
    difficulty.kills += 1
    adjust_difficulty()
    -- todo: spawn explosion
  
    -- spawn powerup
    pwr = ceil(rnd(9))
    -- 1-5 = nothing
    -- 6 = shields
    -- 7-8 = lasers
    -- 9 = missiles
    if pwr >= 9 then
      add(powerups, {
        x = en.x,
        y = en.y,
        sprite = 50,
        deleted = false,
        pickup_behavior =
          missile_powerup
      })
    elseif pwr >= 7 then
      add(powerups, {
        x = en.x,
        y = en.y,
        sprite = 49,
        deleted = false,
        pickup_behavior =
          laser_powerup
      })
    elseif pwr >= 6 then
      add(powerups, {
        x = en.x,
        y = en.y,
        sprite = 48,
        deleted = false,
        pickup_behavior =
          shield_powerup
      })
    end
  end
end

function detect_collisions()
  for pwr in all(powerups) do
    if collide(player.x, player.y,
      8, 8, pwr.x, pwr.y, 8, 8) then
        pwr.pickup_behavior()
        pwr.delete = true
    end
  end
  for en in all(enemies) do
    if collide(player.x, player.y,
      8, 8, en.x, en.y, 8, 8) then
      handle_player_collide()
      en.delete = true
    else
      for bl in all(bullets) do
        if collide(bl.x + ((8-bl.width) / 2),
          bl.y + ((8-bl.height) / 2),
          bl.width, bl.height,
          en.x, en.y, 8, 8) then
          handle_bullet_collide(bl, en)
        end
      end
    end
  end
end

function adjust_difficulty()
  difficulty.max_enemy_life =
    mid(
      3,
      flr(difficulty.kills / 10.0),
      30)
    
  difficulty.enemy_timer =
    60 - mid(0,
      flr(difficulty.kills / 5.0),
     15)
end
--------------------------------

-- powerup functions -----------
function update_powerup(pwr)
  pwr.y += 1
  if pwr.y > 128 then
    pwr.delete = true
  end
end

function draw_powerup(pwr)
  spr(pwr.sprite, pwr.x, pwr.y)
end
--------------------------------

-- ui functions ----------------
function draw_ui()
  draw_ui_background()
  draw_ui_score()
  draw_ui_weapons()
  draw_ui_shields()
end

function draw_ui_background()
  cols = (min_x / 8) - 1
  for x = 0, cols do
    for y = 0, 16 do
      draw_tile(64, x, y)
      if x == cols then
        spr(96, (x*8)+3, y*8)
      end
    end
  end
end

function frame_tiles(x1, y1, x2, y2)
  x1 = x1 - 1
  x2 = x2 + 1
  y1 = y1 - 1
  y2 = y2 + 1
  for x = x1,x2 do
    for y = y1,y2 do
      draw_tile(
        (x == x1 and y == y1) and 80 or
        (x == x2 and y == y1) and 82 or
        (x == x1 and y == y2) and 112 or
        (x == x2 and y == y2) and 114 or
        x == x1 and 96 or
        x == x2 and 98 or
        y == y1 and 81 or
        y == y2 and 113 or
        97, x, y)
    end
  end
end

function draw_ui_score()
  frame_tiles(1, 1, 4, 2)
  print("score", 10, 10)
  print(player.score,
    39 - (#(""..player.score)*4),
    17)
end

function draw_ui_weapons()
  if player.state >
    gamestates.spaceman and
    player.weapon.id >
    weaponids.basic then
    frame_tiles(1, 4, 4, 5)
    print("weapon", 10, 33)
				sprite = 47 + player.weapon.id
    for i = 1, mid(1, player.weapon.exp+1, 5) do
      spr(sprite, 10 + ((i-1)*5), 39)
    end
  end
end

function draw_ui_shields()
  if player.shields != nil then
    frame_tiles(1, 7, 4, 8)
    print("shields", 9, 57)
    for i = 0,
      mid(0, player.shields,8)-1 do
      spr(67,
        8 + (i*4),
        64)
    end
  end
end
--------------------------------
__gfx__
00000000444444440000000000000000000000000000000000000000000000000000000000000000000000000000000044494444444744444449944444977944
00000000444744440000000000000000000000000000000000000000000000000000000000000000000000000000000044494444449a94444497794448777784
00700700447664440000000000000000000000000000000000000000000000000000000000000000000000000000000044444444448a94444897798489a77a98
00077000444d4444000000000000000000000000000000000000000000000000000000000000000000000000000000004444444444498444489aa94448aaaa84
00077000444d4444000000000000000000000000000000000000000000000000000000000000000000000000000000004444444444494444449a9844489aa984
0070070044d4d44400000000000000000000000000000000000000000000000000000000000000000000000000000000444444444448444444899844448a9844
00000000444444440000000000000000000000000000000000000000000000000000000000000000000000000000000044444444444444444449844444498444
00000000444444440000000000000000000000000000000000000000000000000000000000000000000000000000000044444444444444444448444444484444
0000000044455444444b344444455444444aa4440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000044766544444b344444e8824444a44a440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000004766665444b7c3444e888824a444444a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000007466654d64bcc343e48882484a4444a40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000007467c545b4bbb34be487c2424a4444a40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000446cc54446bbbb34448cc244a444444a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000044465444446bb344444824444a4444a40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000044465444444554444448244444a44a440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000444444444448844444477444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000444444444448244444476444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000444444444448244444476444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000444aa4444448244444476444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000444aa4444448244444276244000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000444444444448244447266824000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000444444444448244478266882000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000444444444442244444455444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
46666c14447777444477774400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
67aaaaa147cc1c7447cc1c7400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4666c1147cc821177cc6511700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
67aaaaa17c1821177c16511700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4661111471c821177186581700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
67aaaaa17c1221177885588700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
46c11114471111744711117400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444447777444477774400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
777c77cc777a77aa7776776666614444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7cdcdd117a9a99447656551167a14444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7dcdd1d179a994947565515167914444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ccdd1d10aa994940665515106aa14444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
7dd1d11179949444755151116a914444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cd1d1110a94944406515111069a14444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c1d11110a49444406151111069914444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11001000440040001100100061114444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444444444444444444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444444444444444444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444444444444444444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444444444444444444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444444444444444444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444777777777777774444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444766666666666654444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444765555555555654444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444765101010107654444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444765010101017654444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444765101010107654444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444765010101017654444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444765101010107654444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444765010101017654444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444765101010107654444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444765010101017654444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444767777777777654444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444766666666666654444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444755555555555554444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444444444444444444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444444444444444444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444444444444444444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444444444444444444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444444444444444444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
