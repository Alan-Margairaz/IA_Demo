-- Guards variables
DISTANCE_ALERTE = 200
DISTANCE_PERTE = 400
DISTANCE_ATTAQUE = 64 
DELAI_COMPTEUR = 50
DAMAGE_guard = 10
GUARD_NBR = 5
SPAWN_OFFSET = 30

-- Fireball script
local fireBoids = require("FireBoids")

-- Boids variables (work around because image communication between scripts seems bugged)
local boidImage = love.graphics.newImage('Explosion.png')
local boidHeight = boidImage:getHeight()
local boidWidth = boidImage:getWidth()

-- Guard variables 
local distancesForGuards = {}
distancesForGuards.list = {}
distancesForGuards.dist = 0
distancesForGuards.guard = nil
local closestGuard = nil
local deadGuards = 0

function love.load()
  fullscreen = love.window.setFullscreen(true)
  success = love.window.setMode(W_WIDTH, W_HEIGHT)
end

function get_dist(x1,y1, x2,y2)
  return math.sqrt((x2-x1)^2+(y2-y1)^2)
end

-- calculer angle entre deux points depuis l’origine de l’écran
function get_angle(x1,y1, x2,y2) 
  return math.atan2(y2-y1, x2-x1) 
end


-- on définit le player
local player = {}
player.image = love.graphics.newImage('Player.png')
player.x = (W_WIDTH - player.image:getWidth()) / 2
player.y = W_HEIGHT * 3 / 4
player.speed = 600
player.health = 100
player.spellCooldown = 5
player.lastSpellTime = (player.spellCooldown * -1)
player.bLaunchSpell = false

local bUpdateBoids = false

-- on définit les guards 
local guards = {}
guards.list = {}

function update_image_guard(guard)
  guard.img = 'image_'..guard.etat
end

function Attack(initator, str)
  local time = love.timer.getTime()
  -- Guard case
  if initator and str == "guard" then
    initator.lastAttackTime = time
    if player.health > 0 then
      player.health = player.health - initator.damage
      if player.health <= 0 then
        love.event.quit(0)
      end
    end
  -- Player case
  elseif initator and str == "player" then
    initator.bLaunchSpell = true
    initator.lastAttackTime = time
    fireBoids.launchFireBall(initator)
  end
end

function bCanAttack(initator, str)
  if initator and str == "guard" then
    return love.timer.getTime() - initator.lastAttackTime >= initator.attackCooldown
  elseif initator and str == "player" then
      return love.timer.getTime() - initator.lastSpellTime >= initator.spellCooldown
  end
end

function update_fireball(dt)
  if predatorBoid then
    if findClosestGuardPosition() then
      closestGuard = distancesForGuards.list[1]
      fireBoids.trackPrey(dt, closestGuard.guard, player)
      fireBoids.applyFlocking(dt, false)
    end

  else
    fireBoids.applyFlocking(dt, true, player)
  end
end

function update_guards(dt)
  if deadGuards == #guards.list then
    love.event.quit()
  end

  for _, guard in ipairs(guards.list) do
    -- Position par rapport au player
    local dist = get_dist(guard.x + guard[guard.img]:getWidth()/2, 
                          guard.y + guard[guard.img]:getHeight()/2, 
                          player.x + player.image:getWidth()/2, 
                          player.y + player.image:getHeight()/2)
    local angle = get_angle(guard.x + guard[guard.img]:getWidth()/2, 
                            guard.y + guard[guard.img]:getHeight()/2, 
                            player.x + player.image:getWidth()/2, 
                            player.y + player.image:getHeight()/2)

    if guard.etat == nil then
      print(' ERREUR état guards indéfini (nil)')
    end

    if guard.etat == guard.lst_Etats.GARDE then
      -- dans cet état, on ne fait rien. 
      guard.vx = 0
      guard.vy = 0

      if dist < DISTANCE_ALERTE then
        guard.etat = guard.lst_Etats.CHERCHE
        update_image_guard(guard)
      end

    elseif guard.etat == guard.lst_Etats.CHERCHE then
      guard.vx = guard.speed * math.cos(angle) * dt
      guard.vy = guard.speed * math.sin(angle) * dt

      if dist > DISTANCE_PERTE then
        guard.etat = guard.lst_Etats.PATROUILLE
        update_image_guard(guard)
        -- on charge le compteur
        guard.compteur = DELAI_COMPTEUR

      elseif dist < DISTANCE_ATTAQUE then
        guard.etat = guard.lst_Etats.ATTAQUE
        update_image_guard(guard)
        
        if bCanAttack(guard, "guard") then
          Attack(guard, "guard")    
        end
      end

    elseif guard.etat == guard.lst_Etats.ATTAQUE then
      guard.vx = 0
      guard.vy = 0

      if dist > DISTANCE_ATTAQUE then
        guard.etat = guard.lst_Etats.CHERCHE
        update_image_guard(guard)
      end

    elseif guard.etat == guard.lst_Etats.PATROUILLE then
    
      -- dans cet état on avance dans une direction au hasard et on change 
      if guard.fixe_vitesse_patrouille == false then
        guard.vx = guard.speed * (2 * math.random() -1) * dt
        guard.vy = guard.speed * (2 * math.random() -1) * dt
        guard.fixe_vitesse_patrouille = true
      end
      -- on retourne à l’état de garde si le compteur arrive à 0
      guard.compteur = guard.compteur - 10 * dt 
      if dist > DISTANCE_PERTE and guard.compteur < 0 then
        guard.compteur = 0
        guard.etat = guard.lst_Etats.GARDE
        update_image_guard(guard)
        guard.fixe_vitesse_patrouille = false

      elseif dist < DISTANCE_PERTE then
        guard.etat = guard.lst_Etats.CHERCHE
        guard.compteur = 0
        update_image_guard(guard)
        guard.fixe_vitesse_patrouille = false
      end

    elseif guard.etat == guard.lst_Etats.MORT then
      guard.fixe_vitesse_patrouille = false
      guard.x = guard.x
      guard.y = guard.y
      guard.speed = 0
      
      update_image_guard(guard)
    else
      print('----- ERREUR état guard inconnu :' .. tostring(guard.etat) .. ' -----')
    end

    -- TODO : rajouter un test de collision bord écran 
    guard.x = guard.x + guard.vx
    guard.y = guard.y + guard.vy
  end
end

function update_player(dt)
  if love.keyboard.isDown('up') and player.y > 0 then
    player.y = player.y - player.speed * dt

  elseif love.keyboard.isDown('right')  and player.x < W_HEIGHT - player.image:getWidth() then
    player.x = player.x + player.speed * dt

  elseif love.keyboard.isDown('down') and player.y < W_HEIGHT - player.image:getHeight() then
    player.y = player.y + player.speed * dt

  elseif love.keyboard.isDown('left') and player.x > 0 then
    player.x = player.x - player.speed * dt

  elseif love.mouse.isDown(1) and bCanAttack(player, "player") then
    if not bUpdateBoids then
      bUpdateBoids = true
      Attack(player, "player")
    end
  end
end

function findClosestGuardPosition()
  distancesForGuards.list = {}
  
  for i, guard in ipairs(guards.list) do
    if guard.health > 0 or guard.etat ~= guard.lst_Etats.MORT then
      local currentDistanceForGuard = {}
      currentDistanceForGuard.dist = distance(predatorBoid, guard)
      currentDistanceForGuard.guard = guard

      table.insert(distancesForGuards.list, currentDistanceForGuard)
      if #distancesForGuards.list == (#guards.list - DEAD_GUARDS) then
        table.sort(distancesForGuards.list, function(a, b)
          return a.dist < b.dist
        end)
        return true
      end    
    end
  end
end

function distance(p1, p2) 
  return math.sqrt((p1.x - p2.x)^2 + (p1.y - p2.y)^2)
end

function love.update(dt)
  -- Fireball update when used
  if bUpdateBoids then
    update_fireball(dt)
  end

  update_player(dt)
  update_guards(dt)
  
  if DEAD_GUARDS == GUARD_NBR then
    love.event.quit()
  end
end

function createGuards(idx)
  local guard = {}

  guard.lst_Etats = {}
  guard.lst_Etats.GARDE = 'Garde'
  guard.lst_Etats.CHERCHE = 'Cherche'
  guard.lst_Etats.ATTAQUE = 'Attaque'
  guard.lst_Etats.PATROUILLE = 'Patrouille'
  guard.lst_Etats.MORT = 'Mort'
  guard.etat = guard.lst_Etats.GARDE
  guard.compteur = 0

  for k, v in pairs(guard.lst_Etats) do
    guard['image_'..v] = love.graphics.newImage(v..'.png')
  end
  update_image_guard(guard)

  guard.x = (W_WIDTH - guard[guard.img]:getWidth()) / 3 
            + (idx - 1) * 2 * guard[guard.img]:getWidth()
  guard.y = (W_HEIGHT - guard[guard.img]:getHeight()) / 4
  guard.vx = 0
  guard.vy = 0
  guard.fixe_vitesse_patrouille = false
  guard.health = 100
  guard.speed = 150
  guard.damage = 25
  guard.attackCooldown = 2.5
  guard.lastAttackTime = (guard.attackCooldown * -1)

  return guard
end

-- Creating guards
for idx = 1, GUARD_NBR do
  table.insert(guards.list, createGuards(idx))
end

function love.draw()
  -- Drawing player
  love.graphics.draw(player.image, player.x, player.y)  

  -- Drawing guards
  for _, guard in ipairs(guards.list) do
    love.graphics.draw(guard[guard.img], guard.x, guard.y)
  end
  
  if #followerBoids.list <= 0 then
    bUpdateBoids = false
  end

  -- Drawing fireball follwing boids when triggered used
  if player.bLaunchSpell and bUpdateBoids then
    for index, boid in ipairs(followerBoids.list) do
      love.graphics.draw(boidImage, 
        boid.x + player.image:getWidth()/2, 
        boid.y + player.image:getHeight()/2, 
        -math.atan2(boid.vx, boid.vy), 
        0.67,
        0.67,
        boidWidth/2, 
        boidHeight/2)
    end
  end

  -- Drawing fireball guide for other boids
  if player.bLaunchSpell and predatorBoid and bUpdateBoids then
    love.graphics.draw(boidImage, 
      predatorBoid.x + player.image:getWidth()/2, 
      predatorBoid.y + player.image:getHeight()/2, 
      -math.atan2(predatorBoid.vx, predatorBoid.vy),
      0.67,
      0.67, 
      boidWidth/2, 
      boidHeight/2)
  end
  
  -- "UI" to know when ability is usable
  if not player.bLaunchSpell then
    love.graphics.print("Ability usable with right click!", (W_WIDTH/2), (W_HEIGHT - 50))
  end
end

function love.keypressed(key)
  if key == "escape" then
    love.event.quit()
  end
end