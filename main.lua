--[[
    Hey ! thanks for downloading my mod
    I hope you had/will have fun with this version
    Feel free to check the code here
    Lytebringr
    Mod made by caimez_
--]]

--Settings for the mod
local BlessingAltars = RegisterMod("Blessing Altars",1)
local game = Game()
local hud = game:GetHUD()
local sound = SFXManager()

BlessingAltars.ENTITY_BEGGAR= Isaac.GetEntityTypeByName("Speed Altar")

local CurStage
local RoomConfig

local Register

local EnemiesInRoom

local previouslySpawned = false

local BONUS_CAP={
 SPEED = 10,
 LUCK = 8,
 DAMAGE = 12,
 ABILITY = 20,
 TENACITY = 20,
}


local Bonus={
  Speed=0,
  Luck=0,
  Damage = 0,
  Ability = 0,
  Tenacity = 0,
}

BeggarState = {
  IDLE = 0,
  PAYNOTHING = 2,
  PAYPRIZE = 3,
  PRIZE = 4,
  TELEPORT = 5,
}




local modSetting = {
	ChanceSpawn = 4,
  ReducedStage = 2,
  ReducedSpawnStage = 8,
  PreviouslyCondition = true,
}

-- ModConfigMenu
if ModConfigMenu then --Add some customizable settings
  local modName = "Blessing Altars"
    ModConfigMenu.UpdateCategory(modName, {
    Info = {
      "Customize the spawn of the altars !"
    }
    })

  ModConfigMenu.AddTitle(modName, "Settings", " ")


  ModConfigMenu.AddSetting(modName, "Settings", { --settingTable
      Type = ModConfigMenu.OptionType.NUMBER,
      CurrentSetting = function()
        return modSetting.ChanceSpawn
      end,
      Minimum = 1,
      Default = modSetting.ChanceSpawn,
      Display = function()
        local valeur = modSetting.ChanceSpawn
        
        return "Altar spawnrate : 1 in " .. valeur
      end,
      OnChange = function(currentNumber)
        modSetting.ChanceSpawn = currentNumber
      end,
      Info = function()
        local spawnRoom = modSetting.ChanceSpawn
        local TotalText
        if spawnRoom ~= 1 then
          TotalText = "Altars will spawn once every " .. spawnRoom .. " rooms."
        else
          TotalText = "Altars will always spawn."
        end
        
        return TotalText
      end
    })
  
  ModConfigMenu.AddSpace(modName, "Settings") --Space
  
  ModConfigMenu.AddSetting(modName, "Settings", {
      Type = ModConfigMenu.OptionType.NUMBER,
      CurrentSetting = function()
        return modSetting.ReducedStage
      end,
      Minimum = 0,
      Default = modSetting.ReducedStage,
      Display = function()
        local valeur = modSetting.ReducedStage
        
        return "Chance reduced during the first " .. valeur .. " stages."
      end,
      OnChange = function(currentNumber)
        modSetting.ReducedStage = currentNumber
      end,
      Info = function()
        local reducedStage = modSetting.ReducedStage
        local TotalText
        if reducedStage ~= 0 then
          TotalText = "Altars will spawn less often during the first " .. reducedStage .. " stages."
        else
          TotalText = "Altars will not spawn less often during the firsts stages."
        end
      
        return TotalText
      end
    })
  
  ModConfigMenu.AddSetting(modName, "Settings", {
      Type = ModConfigMenu.OptionType.NUMBER,
      CurrentSetting = function()
        return modSetting.ReducedSpawnStage
      end,
      Minimum = 1,
      Default = modSetting.ReducedSpawnStage,
      Display = function()
        local valeur = modSetting.ReducedSpawnStage
        
        return "Altar spawnrate in firsts stages : 1 in " .. valeur
      end,
      OnChange = function(currentNumber)
        modSetting.ReducedSpawnStage = currentNumber
      end,
      Info = function()
        local reducedSpawnStage = modSetting.ReducedSpawnStage
        local TotalText
        if reducedSpawnStage ~= 1 then
          TotalText = "Altars will spawn once every " .. reducedSpawnStage .. " rooms during the firsts stages."
        else
          TotalText = "Altars will always spawn during the firsts stages."
        end
      
        return TotalText
      end
    })
  
    ModConfigMenu.AddSpace(modName, "Settings")
  
  ModConfigMenu.AddSetting(modName, "Settings", {
		Type = ModConfigMenu.OptionType.BOOLEAN,
		CurrentSetting = function()
			return modSetting.PreviouslyCondition
		end,
		Default = modSetting.PreviouslyCondition,
		Display = function()
			local onOff = "Enabled"
			if modSetting.PreviouslyCondition then
				onOff = "Disabled"
			end
			
			return "Two altars in a row : " .. onOff
		end,
		OnChange = function(currentBool)
			modSetting.PreviouslyCondition = currentBool
		end,
		Info = function()
			local Text = ""
      if modSetting.PreviouslyCondition then
        Text = "not"
      end
			local TotalText = "Altars can" .. Text .. " appear two rooms in a row. (Automatically set for 1 in 1 room spawn)."
			
			return TotalText
		end
	})
  --This setting will be true if the player choose a 1 in 1 chance
  
end





function RemoveFromRegister(entity) --Delete entity from the register
  for j = 1 ,#Register do
    if Register[j].Room == game:GetLevel():GetCurrentRoomIndex()
    and Register[j].Position.X == entity.Position.X
    and Register[j].Position.Y == entity.Position.Y
    and Register[j].Entity.Type == entity.Type
    and Register[j].Entity.Variant == entity.Variant
    then
      table.remove(Register,j)
      break
    end
  end
end




function SpawnRegister()
  for j = 1, #Register do
    
    if Register[j].Room == game:GetLevel():GetCurrentRoomIndex() then
      local entity = Isaac.Spawn(Register[j].Entity.Type, Register[j].Entity.Variant,0,Register[j].Position, Vector(0,0),nil) --Spawn entity from Register
      if Register[j].Entity.Type == BlessingAltars.ENTITY_BEGGAR then --If spawn the special beggar
        local beggarFlag = EntityFlag.FLAG_NO_TARGET | EntityFlag.FLAG_NO_STATUS_EFFECTS --Immune and identification 
        entity:ClearEntityFlags(entity:GetEntityFlags())
        entity:AddEntityFlags(beggarFlag)
        entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYERONLY
        
      end
    end
  end
  
end

function SaveState() --Need to save beggar in Register
  local player = Isaac.GetPlayer(0)
  local SaveData =""
  
  for j = 1, #Register  do
    SaveData = SaveData
    ..string.format("%5u",Register[j].Room)
    ..string.format("%4u",Register[j].Position.X)
    ..string.format("%4u",Register[j].Position.Y)
    ..string.format("%4u",Register[j].Entity.Type)
    ..string.format("%4u",Register[j].Entity.Variant)
  end
  BlessingAltars:SaveData(SaveData)
end



function BlessingAltars:onStarted(fromSave)
  local player = Isaac.GetPlayer(0)
  if fromSave then
    local ModData = BlessingAltars:LoadData()
    Register ={}
    for i = 1, ModData:len(), 21 do --Insert in register from the saved data
      
      table.insert(Register,
        {
          Room  = tonumber(ModData:sub(i,i+4)),
          Position = Vector(tonumber(ModData:sub(i+5,i+8)), tonumber(ModData:sub(i+9,i+12))),
          Entity = {Type = tonumber(ModData:sub(i+13,i+16)), Variant = tonumber(ModData:sub(i+17,i+20))}
        }
      )
    end
    
    
    SpawnRegister()--Spawn the register
    
  else
    local level = game:GetLevel()
    CurStage = level:GetStage()
  end
end

BlessingAltars:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, BlessingAltars.onStarted)


function BlessingAltars:onRoom()
  local room = game:GetRoom()
  --Restart detection
  if game:GetFrameCount() <= 1 then
    Register ={}
    Bonus.Speed = 0 
    Bonus.Luck = 0 
    Bonus.Damage = 0
    Bonus.Ability = 0
    Bonus.Tenacity = 0
    EnemiesInRoom = false
  end
  --NewStage
  local level = game:GetLevel()
  if CurStage ~= level:GetStage() then
    Register={}
  end
  CurStage = level:GetStage()
  SpawnRegister()
  
  EnemiesInRoom = room:GetAliveEnemiesCount() > 0
end

BlessingAltars:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, BlessingAltars.onRoom)


--Save on quit
function BlessingAltars:onExit()
  SaveState()
end
BlessingAltars:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, BlessingAltars.onExit)

--Game may crash
function BlessingAltars:onLevel()
  --SaveState()
end
BlessingAltars:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, BlessingAltars.onLevel)
 

function BlessingAltars:onBeggar(entity)
    local player = Isaac.GetPlayer(0)
    
    local entity = entity:ToNPC()
    local sprite = entity:GetSprite() --To play animation
    local data = entity:GetData()
    local beggarFlag = EntityFlag.FLAG_NO_TARGET | EntityFlag.FLAG_NO_STATUS_EFFECTS --Immune
    
    
    
    if entity:GetEntityFlags()~= beggarFlag then --Just spawned, not in the Register
     entity:ClearEntityFlags(entity:GetEntityFlags())
     entity:AddEntityFlags(beggarFlag)
     entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYERONLY
     local roomIndex = game:GetLevel():GetCurrentRoomIndex()
     table.insert(Register,
       {
         Room = roomIndex,
         Position = entity.Position,
         Entity = {Type = entity.Type, Variant = entity.Variant}
        }
      )
    end
    
    
    if data.Position == nil then 
      data.Position = entity.Position 
    end
    
    entity.Velocity = data.Position - entity.Position
    
    if entity.State == BeggarState.IDLE then
      if entity.StateFrame == 0 then
        sprite:Play("Idle", false)
      end
      
      if (entity.Position - player.Position):Length() <= entity.Size + player.Size then --Collision between beggar and player
        if player:GetNumCoins() > 4 then --  Can modify prince depending on the variant
          sound:Play(SoundEffect.SOUND_SCAMPER, 1, 0, false,1)
          player:AddCoins(-5)
          --No need to check a RNG since it's 100% chance
          entity.State = BeggarState.PAYPRIZE
          entity.StateFrame = -1
        end
        
      end
      
    elseif entity.State == BeggarState.PAYNOTHING then
      if entity.StateFrame == 0 then
        sprite:Play("PayNothing",false)
      elseif sprite:IsFinished("PayNothing") then
        entity.State = BeggarState.IDLE
        entity.StateFrame = -1
      end
      
    elseif entity.State == BeggarState.PAYPRIZE then
      
      if entity.StateFrame == 0 then
        sprite:Play("PayPrize",false)
      elseif sprite:IsFinished("PayPrize") then
        entity.State = BeggarState.PRIZE
        entity.StateFrame = -1
      end
      
    elseif entity.State == BeggarState.PRIZE then
      if entity.StateFrame == 0 then
        sprite:Play("Prize",false)
      elseif sprite:IsEventTriggered("Prize") then
        
        --reward depend on the variant
        
        if entity.Variant == 0 and Bonus.Speed < BONUS_CAP.SPEED then
          Bonus.Speed = Bonus.Speed + 1
          player.MoveSpeed = player.MoveSpeed + 0.05
          
        elseif entity.Variant == 1 and Bonus.Luck < BONUS_CAP.LUCK then
          Bonus.Luck = Bonus.Luck + 1
          player.Luck = player.Luck + 0.5
          
        elseif entity.Variant == 2 and Bonus.Damage < BONUS_CAP.DAMAGE then
          Bonus.Damage = Bonus.Damage + 1
          player.Damage = player.Damage + (1/3)
          
        elseif entity.Variant == 3 and Bonus.Ability < BONUS_CAP.ABILITY then
          Bonus.Ability = Bonus.Ability + 1
          
        elseif entity.Variant == 4 and Bonus.Tenacity < BONUS_CAP.TENACITY then
          Bonus.Tenacity = Bonus.Tenacity + 1
          
        end
        
        player:EvaluateItems()
        entity:GetData().Payout = true 
        
      elseif sprite:IsFinished("Prize") then
        --Disapear if payout
        if entity:GetData().Payout then
          RemoveFromRegister(entity)
          entity.State = BeggarState.TELEPORT
          --Sound
        else
          entity.State = BeggarState.IDLE
        end
        entity.StateFrame = -1
      end
      
    elseif entity.State == BeggarState.TELEPORT then
      if entity.StateFrame == 0 then
        sprite:Play("Teleport", true)
      elseif sprite:IsFinished("Teleport") then
        entity:Remove()
      end
      
    end
    entity.StateFrame = entity.StateFrame + 1
  end 

BlessingAltars:AddCallback(ModCallbacks.MC_NPC_UPDATE,BlessingAltars.onBeggar, BlessingAltars.ENTITY_BEGGAR)

--Our altars are immune to any damage !
function BlessingAltars:onBeggarDamage(target, dmg, flag, source, countdown)
  return false
end
BlessingAltars:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG,BlessingAltars.onBeggarDamage, BlessingAltars.ENTITY_BEGGAR)


function BlessingAltars:onPlayerDamage(target, dmg, flag, source, countdown)
  if Bonus.Tenacity > 0 then
    if Bonus.Tenacity >= math.random(1,100) then
      return false --Immunity
    end
  end
end
BlessingAltars:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG,BlessingAltars.onPlayerDamage, EntityType.ENTITY_PLAYER)




function BlessingAltars:onEvaluate(player,cacheFlag)
--Just set correctly the player's stats on any EvaluateItems since bonuses are temporary
  local player = Isaac.GetPlayer(0)
  if cacheFlag == CacheFlag.CACHE_SPEED then
    player.MoveSpeed = player.MoveSpeed + (0.05 * Bonus.Speed)
  end
  if cacheFlag == CacheFlag.CACHE_LUCK then
    player.Luck = player.Luck + (0.5 * Bonus.Luck)
  end
  if cacheFlag == CacheFlag.CACHE_DAMAGE then
    player.Damage = player.Damage + ((1/3) * Bonus.Damage)
  end

end

BlessingAltars:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, BlessingAltars.onEvaluate)

--If the room is cleared, we now have a chance to spawn an altar
function BlessingAltars:AltarSpawn()
  local room = game:GetRoom()
  local startPos = room:GetBottomRightPos()
  local freePos = room:FindFreePickupSpawnPosition(startPos)
  local player = Isaac.GetPlayer(0)
  local pos = player.Position
  local vel = Vector(0,0)
  local valid = true
  
  --Force to ignore the previouslySpawned altar if the chance are 100% to spawn
  if modSetting.ChanceSpawn == 1 or (modSetting.ReducedSpawnStage == 1 and game:GetLevel():GetStage() <= modSetting.ReducedStage ) then
     previouslySpawned = false
  end
  
  --Or if the setting is off
  if not modSetting.PreviouslyCondition then
    previouslySpawned = false
  end
  
  --Avoid door (extremly rare anyway)
  if not previouslySpawned then
    for i = 0, 8 do
      door = room:GetDoorSlotPosition(i)
      if (i == 0 or i == 4) and (freePos.X == door.X + 40) and (freePos.Y == door.Y) then
        valid = false
      elseif (i == 1 or i == 5) and (freePos.X == door.X) and (freePos.Y == door.Y + 40) then
        valid = false
      elseif (i == 2 or i == 6) and (freePos.X == door.X -40 ) and (freePos.Y == door.Y) then
        valid = false
      elseif (i == 3 or i == 7) and (freePos.X == door.X) and (freePos.Y == door.Y -40 ) then
        valid = false
      end
    end
    
    local chanceSpawn

--Chance to spawn depending on settings
    if game:GetLevel():GetStage() <= modSetting.ReducedStage then
      chanceSpawn = modSetting.ReducedSpawnStage
    else
      chanceSpawn = modSetting.ChanceSpawn
    end

    if valid and (math.random(1,chanceSpawn) == 1) then
      Isaac.Spawn(BlessingAltars.ENTITY_BEGGAR,math.random(0,4),0,freePos,vel,player)
      previouslySpawned = true
    end
    
  else
    previouslySpawned = false
  end
end


function BlessingAltars:onUpdate()
  local player = Isaac.GetPlayer(0)
  --Ability altar
  if Bonus.Ability > 0 and player.FireDelay <= player.MaxFireDelay and player.FireDelay > (player.MaxFireDelay-1) and player:GetShootingJoystick():Length() > 0.1 and not player:HasCollectible(678) then
    local rng = math.random(1, 21 - Bonus.Ability)
    if rng == 1 then
      local speed = math.random(8,14)
      player:FireTear(player.Position,player:GetShootingJoystick():Normalized()*(speed*player.ShotSpeed),true,false,false)
    end
  end
  
  --Is the room cleared 
  local room = game:GetRoom()
  if room:GetAliveEnemiesCount() == 0 and EnemiesInRoom then
    EnemiesInRoom = false
    BlessingAltars.AltarSpawn()
  end
  
end
BlessingAltars:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE,BlessingAltars.onUpdate)

BlessingAltars:onRoom()
BlessingAltars:onLevel()
