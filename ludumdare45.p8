pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
-- configuration --------------
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

function reset_game()
  difficulty.kills = 0
  difficulty.enemy_timer = 60
  difficulty.max_enemy_life = 3

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
  -- todo: replace with gameover screen
  if player.state ==
    gamestates.gameover then
    return
  end
  
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
  debug_info()
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
--------------------------------

-- weapon behaviors ------------
function weapon_basic(bl)
  bl.y -= 1
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
  
  player.x = mid(0, player.x, 120)
  player.y = mid(0, player.y, 120)
end

function draw_player()
  spr(player.sprite,
    player.x, player.y)
  draw_player_fire()
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
       x = rnd(128),
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
  if player.sprite > 1 then
    sprite = 19
  end

  spr(sprite, en.x, en.y)
  update_animation(en.fire,
    fire_anim[2])
  spr(fire_anim[2][en.fire.frame],
    en.x, en.y-8, 1, 1, false,
    true)  
end

function handle_player_collide()
  if player.state ==
    gamestates.spaceman then
    player.state = gamestates.in_ship
    player.sprite = 18
  elseif player.shields == nil then
    player.state = gamestates.gameover
    -- todo: spawn explosion
  else
    player.shields -= 1
    if player.shields < 0 then
      player.state = gamestates.gameover
      -- todo: spawn explosion
    end
  end
end

function handle_bullet_collide(bl, en)
  en.life -= bl.damage
  bl.delete = true

  if en.life <= 0 then
    en.delete = true
    difficulty.kills += 1
    adjust_difficulty()
    -- todo: spawn explosion
  
    -- spawn powerup
    pwr = ceil(rnd(8))
    -- 1-5 = nothing
    -- 6 = shields
    -- 7 = lasers
    -- 8 = missiles
    if pwr >= 8 then
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
      flr(difficulty.kills / 10.0),
      45)
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
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000090000000700000009900000977900
00000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000090000009a90000097790008777780
00700700007460000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008a90000897798089a77a98
00077000000d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000098000089aa90008aaaa80
00077000000d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000090000009a9800089aa980
0070070000d0d00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000000899800008a9800
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009800000098000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000000080000
0000000000055000000b300000055000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000766500000b300000e88200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000766665000b7c3000e888820000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000007066650d60bcc303e0888208000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000007067c505b0bbb30be087c202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000006cc50006bbbb30008cc200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000065000006bb30000082000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000650000005500000082000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000008800000077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000008200000076000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000008200000076000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000aa0000008200000076000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000aa0000008200000276200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000008200007266820000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000008200078266882000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000002200000055000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06666c10007777000077770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
67aaaaa107cc1c7007cc1c7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0666c1107cc821177cc6511700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
67aaaaa17c1821177c16511700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0661111071c821177186581700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
67aaaaa17c1221177885588700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06c11110071111700711117000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000007777000077770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
