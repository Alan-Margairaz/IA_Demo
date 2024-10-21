-- calculer distance euclidienne entre deux points
DISTANCE_ALERTE = 200
DISTANCE_PERTE = 400
DISTANCE_ATTAQUE = 64 
DELAI_COMPTEUR = 50
VITESSE_guard = 45
LARGEUR_ECRAN = 1600
HAUTEUR_ECRAN = 1200

START_TIME = 0
local fireBoids = require("FireBoids")
local cooldownValue = 5
local bUnderCooldown = false

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
player.x = (LARGEUR_ECRAN - player.image:getWidth()) / 2 
player.y = HAUTEUR_ECRAN * 3 / 4
player.speed = 200

-- on définit le guard 
local guard = {}

-- on définit les états possibles
guard.lst_Etats = {}
guard.lst_Etats.GARDE = 'Garde'
guard.lst_Etats.CHERCHE = 'Cherche'
guard.lst_Etats.ATTAQUE = 'Attaque'
guard.lst_Etats.PATROUILLE = 'Patrouille'
guard.etat = guard.lst_Etats.GARDE
guard.compteur = 0

for k, v in pairs(guard.lst_Etats) do
    print(k, v)
    guard['image_'..v] = love.graphics.newImage(v..'.png')
end

guard.x = (LARGEUR_ECRAN - guard.image_Garde:getWidth()) / 2
guard.y = 0
guard.vx = 0 
guard.vy = 0
guard.fixe_vitesse_patrouille = false

function update_image_guard()
  guard.image_courante = 'image_'..guard.etat
end
update_image_guard()

function getGuardImage()
  return guard.image_courante
end

function update_cooldown(dt)
  local currentTime = love.timer.getTime() - START_TIME

  if currentTime >= cooldownValue and bUnderCooldown then
    bUnderCooldown = false
  end
end


function update_guard(dt)


  -- on aura besoin de connaître la position par rapport au player
  local dist = get_dist(guard.x + guard[guard.image_courante]:getWidth()/2, 
                        guard.y + guard[guard.image_courante]:getHeight()/2, 
                        player.x + player.image:getWidth()/2, 
                        player.y + player.image:getHeight()/2)
  local angle = get_angle(guard.x + guard[guard.image_courante]:getWidth()/2, 
                          guard.y + guard[guard.image_courante]:getHeight()/2, 
                          player.x + player.image:getWidth()/2, 
                          player.y + player.image:getHeight()/2)

  if guard.etat == nil then

    print(' ERREUR état guard indéfini (nil)')

  end


  if guard.etat == guard.lst_Etats.GARDE then

    -- dans cet état, on ne fait rien. 
    guard.vx = 0
    guard.vy = 0

    -- On attend juste que le player passe à proximité
    -- ce qui nous amènera à l’état « cherche »

    if dist < DISTANCE_ALERTE then
      guard.etat = guard.lst_Etats.CHERCHE
      update_image_guard()
    end

  elseif guard.etat == guard.lst_Etats.CHERCHE then

    -- dans cet état on se dirige vers le player s’il n’est pas trop loin
    guard.vx = VITESSE_guard * math.cos(angle) * dt
    guard.vy = VITESSE_guard * math.sin(angle) * dt

    if dist > DISTANCE_PERTE then
      guard.etat = guard.lst_Etats.PATROUILLE
      update_image_guard()
      -- on charge le compteur
      guard.compteur = DELAI_COMPTEUR

    elseif dist < DISTANCE_ATTAQUE then
      guard.etat = guard.lst_Etats.ATTAQUE
      update_image_guard()
    end

  elseif guard.etat == guard.lst_Etats.ATTAQUE then
    -- dans cet état, on attaque. Pas implémenté ici
    -- on pourrait faire perdre des PV au player, etc.
    -- dans tous les cas la guard s’immobilise quand elle attaque
    guard.vx = 0
    guard.vy = 0

    -- on prévoit quand même une sortie de l’état si le player s’est éloigné

    if dist > DISTANCE_ATTAQUE then
      guard.etat = guard.lst_Etats.CHERCHE
      update_image_guard()
    end

  elseif guard.etat == guard.lst_Etats.PATROUILLE then
   
    -- dans cet état on avance dans une direction au hasard et on change 
    if guard.fixe_vitesse_patrouille == false then
      guard.vx = VITESSE_guard * (2 * math.random() -1) * dt
      guard.vy = VITESSE_guard * (2 * math.random() -1) * dt
      guard.fixe_vitesse_patrouille = true
    end
    -- on retourne à l’état de garde si le compteur arrive à 0
    guard.compteur = guard.compteur - 10 * dt 
    if dist > DISTANCE_PERTE and guard.compteur < 0 then
      guard.compteur = 0
      guard.etat = guard.lst_Etats.GARDE
      update_image_guard()
      guard.fixe_vitesse_patrouille = false

    elseif dist < DISTANCE_PERTE then
      guard.etat = guard.lst_Etats.CHERCHE
      guard.compteur = 0
      update_image_guard()
      guard.fixe_vitesse_patrouille = false
    end

  else

    print('----- ERREUR état guard inconnu :' .. tostring(guard.etat) .. ' -----')

  end

--  rajouter un test de collision bord écran 
    guard.x = guard.x + guard.vx
    guard.y = guard.y + guard.vy
    
end


function update_player(dt)

  if love.keyboard.isDown('up') and player.y > 0 then
    player.y = player.y - player.speed * dt

  elseif love.keyboard.isDown('right')  and player.x < LARGEUR_ECRAN - player.image:getWidth() then
    player.x = player.x + player.speed * dt

  elseif love.keyboard.isDown('down') and player.y < HAUTEUR_ECRAN - player.image:getHeight() then
    player.y = player.y + player.speed * dt

  elseif love.keyboard.isDown('left') and player.x > 0 then
    player.x = player.x - player.speed * dt

  elseif love.mouse.isDown(1) and not bUnderCooldown then
    if not bUnderCooldown then
      local currentGuardImage = getGuardImage()
      START_TIME = love.timer:getTime()
      bUnderCooldown = true
      fireBoids.launchFireBall(guard, player, player.image)
    else
      print("Ability still in cooldown")
    end
  end

end


function love.update(dt)

    update_player(dt)
    update_guard(dt)
    update_cooldown(dt)

end


function love.draw()
  love.graphics.draw(guard[guard.image_courante], guard.x, guard.y)
  love.graphics.draw(player.image, player.x, player.y)

end


function love.keypressed(key)
  if key == "escape" then
    love.event.quit()
  end
end