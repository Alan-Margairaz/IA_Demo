-- calculer distance euclidienne entre deux points
DISTANCE_ALERTE = 200
DISTANCE_PERTE = 400
DISTANCE_ATTAQUE = 64 
DELAI_COMPTEUR = 50
VITESSE_guard = 45
GUARD_NBR = 5

local startTime = 0
local fireBoids = require("FireBoids")
local cooldownValue = 10
local bUnderCooldown = false

local boidImage = love.graphics.newImage('Explosion.png')
local boidHeight = boidImage:getHeight()
local boidWidth = boidImage:getWidth()

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

-- on définit les guards 
local guards = {}
guards.list = {}
guards.y = (W_HEIGHT - guards.image_Garde:getHeight()) / 4
local firstGuardX = W_WIDTH - guards.image_Garde:getWidth() / 2


function update_image_guards()
  guards.image_courante = 'image_'..guards.etat
end
update_image_guards()

function getguardsImage()
  return guards.image_courante
end

function update_cooldown(dt)
  local currentTime = love.timer.getTime() - startTime

  if currentTime >= cooldownValue and bUnderCooldown then
    bUnderCooldown = false
    bTouchedtarget = false
    bPredatorDead = false
  end
end


function update_guards(dt)
  -- Position par rapport au player
  local dist = get_dist(guards.x + guards[guards.image_courante]:getWidth()/2, 
                        guards.y + guards[guards.image_courante]:getHeight()/2, 
                        player.x + player.image:getWidth()/2, 
                        player.y + player.image:getHeight()/2)
  local angle = get_angle(guards.x + guards[guards.image_courante]:getWidth()/2, 
                          guards.y + guards[guards.image_courante]:getHeight()/2, 
                          player.x + player.image:getWidth()/2, 
                          player.y + player.image:getHeight()/2)

  if guards.etat == nil then

    print(' ERREUR état guards indéfini (nil)')

  end


  if guards.etat == guards.lst_Etats.GARDE then

    -- dans cet état, on ne fait rien. 
    guards.vx = 0
    guards.vy = 0

    -- On attend juste que le player passe à proximité
    -- ce qui nous amènera à l’état « cherche »

    if dist < DISTANCE_ALERTE then
      guards.etat = guards.lst_Etats.CHERCHE
      update_image_guards()
    end

  elseif guards.etat == guards.lst_Etats.CHERCHE then

    -- dans cet état on se dirige vers le player s’il n’est pas trop loin
    guards.vx = VITESSE_guards * math.cos(angle) * dt
    guards.vy = VITESSE_guards * math.sin(angle) * dt

    if dist > DISTANCE_PERTE then
      guards.etat = guards.lst_Etats.PATROUILLE
      update_image_guards()
      -- on charge le compteur
      guards.compteur = DELAI_COMPTEUR

    elseif dist < DISTANCE_ATTAQUE then
      guards.etat = guards.lst_Etats.ATTAQUE
      update_image_guards()
    end

  elseif guards.etat == guards.lst_Etats.ATTAQUE then
    -- dans cet état, on attaque. Pas implémenté ici
    -- on pourrait faire perdre des PV au player, etc.
    -- dans tous les cas la guards s’immobilise quand elle attaque
    guards.vx = 0
    guards.vy = 0

    -- on prévoit quand même une sortie de l’état si le player s’est éloigné

    if dist > DISTANCE_ATTAQUE then
      guards.etat = guards.lst_Etats.CHERCHE
      update_image_guards()
    end

  elseif guards.etat == guards.lst_Etats.PATROUILLE then
   
    -- dans cet état on avance dans une direction au hasard et on change 
    if guards.fixe_vitesse_patrouille == false then
      guards.vx = VITESSE_guards * (2 * math.random() -1) * dt
      guards.vy = VITESSE_guards * (2 * math.random() -1) * dt
      guards.fixe_vitesse_patrouille = true
    end
    -- on retourne à l’état de garde si le compteur arrive à 0
    guards.compteur = guards.compteur - 10 * dt 
    if dist > DISTANCE_PERTE and guards.compteur < 0 then
      guards.compteur = 0
      guards.etat = guards.lst_Etats.GARDE
      update_image_guards()
      guards.fixe_vitesse_patrouille = false

    elseif dist < DISTANCE_PERTE then
      guards.etat = guards.lst_Etats.CHERCHE
      guards.compteur = 0
      update_image_guards()
      guards.fixe_vitesse_patrouille = false
    end

  else

    print('----- ERREUR état guards inconnu :' .. tostring(guards.etat) .. ' -----')

  end

--  rajouter un test de collision bord écran 
    guards.x = guards.x + guards.vx
    guards.y = guards.y + guards.vy
    
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

  elseif love.mouse.isDown(1) and not bUnderCooldown then
    if not bUnderCooldown then
      local currentguardsImage = getguardsImage()
      startTime = love.timer:getTime()
      bUnderCooldown = true
      fireBoids.launchFireBall(guards, player, player.image)
    end
  end

end


function love.update(dt)
    update_player(dt)
    update_guards(dt)
    update_cooldown(dt)

    if bUnderCooldown then
      fireBoids.checkBoidPositions(guards)
      if not bPredatorDead then
        fireBoids.trackPrey(dt, guards, player)
        fireBoids.applyFlocking(dt, false, guards)
      else
        fireBoids.applyFlocking(dt, true, guards)
      end
    end
end

function createGuards()
  local guard = {}

  guard.x = firstGuardX + (i - 1) * 2 * guards.image_Garde:getWidth()
  guard.y = guards.y
  guard.vx = 0 
  guard.vy = 0
  guard.fixe_vitesse_patrouille = false

  -- on définit les états possibles
  guard.lst_Etats = {}
  guard.lst_Etats.GARDE = 'Garde'
  guard.lst_Etats.CHERCHE = 'Cherche'
  guard.lst_Etats.ATTAQUE = 'Attaque'
  guard.lst_Etats.PATROUILLE = 'Patrouille'
  guard.etat = guards.lst_Etats.GARDE
  guard.compteur = 0

  for k, v in pairs(guard.lst_Etats) do
    guard['image_'..v] = love.graphics.newImage(v..'.png')
  end

  return guard
end

function love.draw()
  -- Drawing player
  love.graphics.draw(player.image, player.x, player.y)  

  -- Drawing guards
  for i = 1, GUARD_NBR do
    table.insert(guards.list, createGuards())
  end

  for _, guard in ipairs(guards.list) do
    love.graphics.draw(guard[guards.image_courante], guard.x, guard.y)
  end
  
  -- Drawing fireball when ability used
  if bUnderCooldown and not bTouchedtarget then
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
  if bUnderCooldown and not bPredatorDead then
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
  if bUnderCooldown then
    love.graphics.print("Ability still in cooldown", 20, 200)
  end
end


function love.keypressed(key)
  if key == "escape" then
    love.event.quit()
  end
end