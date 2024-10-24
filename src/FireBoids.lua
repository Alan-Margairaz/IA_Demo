-- TO DO
-- o align
--
-- **********************************
-- Demo variables
-- *********************************
local fireBoids = {}

-- Constants
W_WIDTH = love.graphics.getWidth()
W_HEIGHT = love.graphics.getHeight()
W_LIMIT = 40

DETECTION_VARIANCE = 1

N_BOIDS = 41
CVISUAL_RANGE = 60 -- could be an individual boid property
DEAD_ANGLE = 60
V_TURN = 2 -- could be an individual boid property
MINDISTANCE = 10
VMAX = 300
DAMAGE = 50

FOLLOWER_AVOIDANCE = 5 
FOLLOWER_COHESION = 4 
FOLLOWER_CENTERING = 200
FOLLOWER_CONVERGING = 300

predatorBoid = {}
predatorBoid.img = nil

followerBoids = {}
followerBoids.list = {}
followerBoids.img = nil

local boids = {}
boids.list = {}

local predatorLastPos = {}
predatorLastPos.x = 0
predatorLastPos.y = 0

DEAD_GUARDS = 0
-- ****************************
-- Fonctions
-- ****************************

function fireBoids.trackPrey(dt, target, player)
  if predatorBoid then 
    if target then
      local closestTarget = nil
      local closestDistance = math.huge

      if closestDistance > 0 then
        closestTarget = target
        closestDistance = distance(predatorBoid, closestTarget)
      if math.abs(closestDistance) <= DETECTION_VARIANCE then
        applyDamage(target)
        destroyBoid(predatorBoid, player)
        return
      end   
    end

    -- Calculating the prey's future position 
    local futurePosition = {
        x = closestTarget.x + closestTarget.vx * dt,
        y = closestTarget.x + closestTarget.vy * dt
    }

    -- Calculating the force to get to the target
    local force = {
      x = futurePosition.x - predatorBoid.x,
      y = futurePosition.y - predatorBoid.y
    }

    local magnitude = math.sqrt(force.x^2 + force.y^2)
    if magnitude > 0 then
      force.x = (force.x/magnitude) * VMAX
      force.y = (force.y/magnitude) * VMAX
    end

    predatorBoid.vx = predatorBoid.vx + force.x * dt
    predatorBoid.vy = predatorBoid.vy + force.y * dt

    local speed = math.sqrt(predatorBoid.vx^2 + predatorBoid.vy^2)
    if speed > VMAX then
      predatorBoid.vx = (predatorBoid.vx / speed) * VMAX
      predatorBoid.vy = (predatorBoid.vy / speed) * VMAX
    end

      local preyAngle = angle(predatorBoid, closestTarget)
    predatorBoid.x = predatorBoid.x + speed * math.cos(preyAngle) * dt
    predatorBoid.y = predatorBoid.y + speed * math.sin(preyAngle) * dt 

    predatorLastPos = {}
    predatorLastPos.x = predatorBoid.x
    predatorLastPos.y = predatorBoid.y
    end
  end
end

function applyDamage(target)
  if target.health > 0 then
    target.health = target.health - DAMAGE
    if target.health <= 0 then
      target.etat = target.lst_Etats.MORT
      DEAD_GUARDS = DEAD_GUARDS + 1
    else
      local randState = love.math.random()
      if randState < 0.5 then
        target.etat = target.lst_Etats.CHERCHE
      else
        target.etat = target.lst_Etats.PATROUILLE
      end
    end
  end
end

-- ****************************
-- Boids flocking behavior
-- ****************************

function cohesion(pBoid, pVisualRange)

  local delta = {}
  local dVx = 0
  local dVy = 0
  local nearBoids = {}
  local sumX = 0
  local sumY = 0
  local sumVx = 0
  local sumVy = 0
  local n = 0

  for index, otherBoid in ipairs(followerBoids.list) do
    if distance(pBoid, otherBoid) < pVisualRange then
      sumX = sumX + otherBoid.x
      sumY = sumY + otherBoid.y
      sumVx = sumVx + otherBoid.vx
      sumVy = sumVy + otherBoid.vy
      n = n + 1
    end
  end

  delta.dx = sumX/n - pBoid.x
  delta.dy = sumY/n - pBoid.y
  delta.dVx = sumVx/n - pBoid.vx 
  delta.dVy = sumVy/n - pBoid.vy
  
  return delta

end

function keepDistance(pBoid, pMinDistance)

  local dist = {}
  dist.dx = 0
  dist.dy = 0
  
  for index, otherBoid in ipairs(followerBoids.list) do
    if pBoid ~= otherBoid then
      if distance(otherBoid, pBoid) < pMinDistance then
        dist.dx = dist.dx + (pBoid.x - otherBoid.x)
        dist.dy = dist.dy + (pBoid.y - otherBoid.y)
      end
    end
  end

  return dist 

end

function keepInside(pBoid, pVTurn, pLimit)

  local turn = {}
  turn.dVx = 0
  turn.dVy = 0


  if pBoid.x < pLimit then
    turn.dVx = pVTurn
  end

  if pBoid.x > W_WIDTH - pLimit then
    turn.dVx = - pVTurn
  end

  if pBoid.y < pLimit then
    turn.dVy = pVTurn 
  end

  if pBoid.y > W_HEIGHT - pLimit then
    turn.dVy = - pVTurn 
  end

  return turn 
end

function convergeTo(pBoid)
  local finalAngle = {}
  finalAngle.x = 0
  finalAngle.y = 0

  local angleToTarget
  if not predatorBoid and predatorLastPos then
    angleToTarget = math.atan2((predatorLastPos.y - pBoid.y), (predatorLastPos.x - pBoid.x))
  else
    angleToTarget = math.atan2((predatorBoid.y - pBoid.y), (predatorBoid.x - pBoid.x))
  end

  finalAngle.x = math.cos(angleToTarget)
  finalAngle.y = math.sin(angleToTarget)

  return finalAngle
end

-- ****************************
-- INITIALISATION
-- ****************************

function fireBoids.launchFireBall(player)
  for n = 1, N_BOIDS do
    if n == 1 then
        predatorBoid = createBoid(true, player)
    else
        table.insert(followerBoids.list, createBoid(false, player))
    end
  end
end

function createBoid(bIsPredator, player)
  if boidType then
    predatorBoid.x = player.x
    predatorBoid.y = player.y
    predatorBoid.vx = VMAX
    predatorBoid.vy = VMAX 

    return predatorBoid
  else
    local followerBoid = {}

    followerBoid.x = player.x
    followerBoid.y = player.y
    followerBoid.vx = math.random(-VMAX, VMAX)
    followerBoid.vy = math.random(-VMAX, VMAX)

    return followerBoid
  end
end

-- ****************************
-- UPDATE
-- ****************************

function distance(pBoid1, pBoid2) 
  return math.sqrt((pBoid1.x - pBoid2.x)^2 + (pBoid1.y - pBoid2.y)^2)
end

function angle(start, arrival)
  return get_angle(start.x, start.y, arrival.x, arrival.y)
end

function splitFireBall(dt)
  for _, boid in ipairs(followerBoids.list) do
      boid.vx = boid.vx + (avoidanceForce.dx * 100
      + centeringForce.dVx * 0
      + (cohesionForce.dx 
        + cohesionForce.dVx) * 0
        + attractionForce.x * 0
    ) * dt

    boid.vy = boid.vy + (avoidanceForce.dy * 100
    + centeringForce.dVy * 0
    + (cohesionForce.dy 
      + cohesionForce.dVy) * 0
      + attractionForce.y * 0
    ) * dt
  end
end

function fireBoids.applyFlocking(dt, bSplitFireball, player)
  if bSplitFireball then    
    local angleIncrement = 9 * (math.pi/180)    

    for i, boid in ipairs(followerBoids.list) do
      if boid.x >= W_WIDTH or boid.y >= W_HEIGHT then
        destroyBoid(boid, player)
      end

      local angle = i * angleIncrement

      local speed = VMAX * 3
      boid.vx = speed * math.cos(angle) 
      boid.vy = speed * math.sin(angle)

      boid.x = boid.x + boid.vx * dt
      boid.y = boid.y + boid.vy * dt 
    end
  else    
    for index, boid in ipairs(followerBoids.list) do 
      -- align position and speed with that of others
      cohesionForce = cohesion(boid, CVISUAL_RANGE)
      -- boids avoid each other
      avoidanceForce = keepDistance(boid, MINDISTANCE)
      -- boids return to the center when approching window’s edges
      centeringForce = keepInside(boid, V_TURN, W_LIMIT)

      attractionForce = convergeTo(boid)

      -- boids speed adjustement according all forces
      -- we could add ponderations
      boid.vx = boid.vx + (avoidanceForce.dx * FOLLOWER_AVOIDANCE
                            + centeringForce.dVx * FOLLOWER_CENTERING
                            + (cohesionForce.dx 
                              + cohesionForce.dVx) * FOLLOWER_COHESION
                              + attractionForce.x * FOLLOWER_CONVERGING
                          ) * dt

      boid.vy = boid.vy + (avoidanceForce.dy * FOLLOWER_AVOIDANCE
                          + centeringForce.dVy * FOLLOWER_CENTERING
                          + (cohesionForce.dy 
                            + cohesionForce.dVy) * FOLLOWER_COHESION
                            + attractionForce.y * FOLLOWER_CONVERGING
                          ) * dt

      -- speed limitation
      if math.abs(boid.vx) > VMAX then
        boid.vx = boid.vx/math.abs(boid.vx) * VMAX
      end
      if math.abs(boid.vy) > VMAX then
        boid.vy = boid.vy/math.abs(boid.vy) * VMAX
      end

      -- move boid according to its speed
      boid.x = boid.x + boid.vx * dt
      boid.y = boid.y + boid.vy * dt
    end
  end
end

-- ****************************
-- CLEANUP 
-- ****************************

function destroyBoid(boidToDestroy, player)
  if boidToDestroy == predatorBoid then
    predatorBoid = nil
  else
    if table.remove(followerBoids.list, followerBoids.list[boidToDestroy]) then
      followerBoids.list[boidToDestroy] = nil
      player.bLaunchSpell = false
    end
  end  
end

return fireBoids