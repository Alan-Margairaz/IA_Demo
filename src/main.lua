-- calculer distance euclidienne entre deux points
DISTANCE_ALERTE = 200
DISTANCE_PERTE = 400
DISTANCE_ATTAQUE = 64 
DELAI_COMPTEUR = 50
VITESSE_SENTINELLE = 45
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


-- on définit le joueur
local joueur = {}
joueur.image = love.graphics.newImage('Joueur.png')
joueur.x = (LARGEUR_ECRAN - joueur.image:getWidth()) / 2 
joueur.y = HAUTEUR_ECRAN * 3 / 4
joueur.speed = 200

-- on définit la sentinelle 
local sentinelle = {}

-- on définit les états possibles
sentinelle.lst_Etats = {}
sentinelle.lst_Etats.GARDE = 'Garde'
sentinelle.lst_Etats.CHERCHE = 'Cherche'
sentinelle.lst_Etats.ATTAQUE = 'Attaque'
sentinelle.lst_Etats.PATROUILLE = 'Patrouille'
sentinelle.etat = sentinelle.lst_Etats.GARDE
sentinelle.compteur = 0

for k, v in pairs(sentinelle.lst_Etats) do
    print(k, v)
    sentinelle['image_'..v] = love.graphics.newImage(v..'.png')
end

sentinelle.x = (LARGEUR_ECRAN - sentinelle.image_Garde:getWidth()) / 2
sentinelle.y = 0
sentinelle.vx = 0 
sentinelle.vy = 0
sentinelle.fixe_vitesse_patrouille = false

function update_image_sentinelle()

  sentinelle.image_courante = 'image_'..sentinelle.etat

end

update_image_sentinelle()


function update_cooldown(dt)
  local currentTime = love.timer.getTime() - START_TIME

  if currentTime >= cooldownValue then
    bUnderCooldown = false
  end
end


function update_sentinelle(dt)


  -- on aura besoin de connaître la position par rapport au joueur
  local dist = get_dist(sentinelle.x + sentinelle[sentinelle.image_courante]:getWidth()/2, 
                        sentinelle.y + sentinelle[sentinelle.image_courante]:getHeight()/2, 
                        joueur.x + joueur.image:getWidth()/2, 
                        joueur.y + joueur.image:getHeight()/2)
  local angle = get_angle(sentinelle.x + sentinelle[sentinelle.image_courante]:getWidth()/2, 
                          sentinelle.y + sentinelle[sentinelle.image_courante]:getHeight()/2, 
                          joueur.x + joueur.image:getWidth()/2, 
                          joueur.y + joueur.image:getHeight()/2)

  if sentinelle.etat == nil then

    print(' ERREUR état sentinelle indéfini (nil)')

  end


  if sentinelle.etat == sentinelle.lst_Etats.GARDE then

    -- dans cet état, on ne fait rien. 
    sentinelle.vx = 0
    sentinelle.vy = 0

    -- On attend juste que le joueur passe à proximité
    -- ce qui nous amènera à l’état « cherche »

    if dist < DISTANCE_ALERTE then
      sentinelle.etat = sentinelle.lst_Etats.CHERCHE
      update_image_sentinelle()
    end

  elseif sentinelle.etat == sentinelle.lst_Etats.CHERCHE then

    -- dans cet état on se dirige vers le joueur s’il n’est pas trop loin
    sentinelle.vx = VITESSE_SENTINELLE * math.cos(angle) * dt
    sentinelle.vy = VITESSE_SENTINELLE * math.sin(angle) * dt

    if dist > DISTANCE_PERTE then
      sentinelle.etat = sentinelle.lst_Etats.PATROUILLE
      update_image_sentinelle()
      -- on charge le compteur
      sentinelle.compteur = DELAI_COMPTEUR

    elseif dist < DISTANCE_ATTAQUE then
      sentinelle.etat = sentinelle.lst_Etats.ATTAQUE
      update_image_sentinelle()
    end

  elseif sentinelle.etat == sentinelle.lst_Etats.ATTAQUE then
    -- dans cet état, on attaque. Pas implémenté ici
    -- on pourrait faire perdre des PV au joueur, etc.
    -- dans tous les cas la sentinelle s’immobilise quand elle attaque
    sentinelle.vx = 0
    sentinelle.vy = 0

    -- on prévoit quand même une sortie de l’état si le joueur s’est éloigné

    if dist > DISTANCE_ATTAQUE then
      sentinelle.etat = sentinelle.lst_Etats.CHERCHE
      update_image_sentinelle()
    end

  elseif sentinelle.etat == sentinelle.lst_Etats.PATROUILLE then
   
    -- dans cet état on avance dans une direction au hasard et on change 
    if sentinelle.fixe_vitesse_patrouille == false then
      sentinelle.vx = VITESSE_SENTINELLE * (2 * math.random() -1) * dt
      sentinelle.vy = VITESSE_SENTINELLE * (2 * math.random() -1) * dt
      sentinelle.fixe_vitesse_patrouille = true
    end
    -- on retourne à l’état de garde si le compteur arrive à 0
    sentinelle.compteur = sentinelle.compteur - 10 * dt 
    if dist > DISTANCE_PERTE and sentinelle.compteur < 0 then
      sentinelle.compteur = 0
      sentinelle.etat = sentinelle.lst_Etats.GARDE
      update_image_sentinelle()
      sentinelle.fixe_vitesse_patrouille = false

    elseif dist < DISTANCE_PERTE then
      sentinelle.etat = sentinelle.lst_Etats.CHERCHE
      sentinelle.compteur = 0
      update_image_sentinelle()
      sentinelle.fixe_vitesse_patrouille = false
    end

  else

    print('----- ERREUR état sentinelle inconnu :' .. tostring(sentinelle.etat) .. ' -----')

  end

--  rajouter un test de collision bord écran 
    sentinelle.x = sentinelle.x + sentinelle.vx
    sentinelle.y = sentinelle.y + sentinelle.vy

end


function update_joueur(dt)

  if love.keyboard.isDown('up') and joueur.y > 0 then
    joueur.y = joueur.y - joueur.speed * dt

  elseif love.keyboard.isDown('right')  and joueur.x < LARGEUR_ECRAN - joueur.image:getWidth() then
    joueur.x = joueur.x + joueur.speed * dt

  elseif love.keyboard.isDown('down') and joueur.y < HAUTEUR_ECRAN - joueur.image:getHeight() then
    joueur.y = joueur.y + joueur.speed * dt

  elseif love.keyboard.isDown('left') and joueur.x > 0 then
    joueur.x = joueur.x - joueur.speed * dt

  elseif love.mouse.isDown(1) and not bUnderCooldown then
    START_TIME = love.timer:getTime()
    bUnderCooldown = true
    fireBoids:launchFireBall()
  end

end


function love.update(dt)

    update_joueur(dt)
    update_sentinelle(dt)
    update_cooldown(dt)

end


function love.draw()
  love.graphics.draw(sentinelle[sentinelle.image_courante], sentinelle.x, sentinelle.y)
  love.graphics.draw(joueur.image, joueur.x, joueur.y)

end


function love.keypressed(key)
  if key == "escape" then
    love.event.quit()
  end
end