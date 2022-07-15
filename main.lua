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

local CurStage
local RoomConfig

local Register


BeggarState = {
  IDLE = 0,
  PAYNOTHING = 2,
  PAYPRIZE = 3,
  PRIZE = 4,
  TELEPORT = 5,
}



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
  Isaac.ConsoleOutput("spawn")
  Isaac.ConsoleOutput(#Register)
  Isaac.ConsoleOutput("\n")
  for j = 1, #Register do
    
    if Register[j].Room == game:GetLevel():GetCurrentRoomIndex() then
      local entity = Isaac.Spawn(Register[j].Entity.Type, Register[j].Entity.Variant,0,Register[j].Position, Vector(0,0),nil) --Spawn entity from Register
      if Register[j].Entity.Type == BlessingAltars.ENTITY_BEGGAR then --If spawn the special beggar
        local beggarFlag = EntityFlag.FLAG_NO_TARGET | EntityFlag.FLAG_NO_STATUS_EFFECTS --Immune
        entity:ClearEntityFlags(entity:GetEntityFlags())
        entity:AddEntityFlags(beggarFlag)
        entity.EntityCollisionClass = EntityCollisionClass.ENTCOLL_PLAYERONLY
        entity.SpriteOffset = Vector(0,4) --Fix height of the beggar
        
      end
    end
  end
  
end

function SaveState() --Need to save beggar in Register
  local player = Isaac.GetPlayer(0)
  local SaveData =""
  
    Isaac.ConsoleOutput("\nregister")
    Isaac.ConsoleOutput(#Register)
  for j = 1, #Register  do
    SaveData = SaveData
    ..string.format("%5u",Register[j].Room)
    ..string.format("%4u",Register[j].Position.X)
    ..string.format("%4u",Register[j].Position.Y)
    ..string.format("%4u",Register[j].Entity.Type)
    ..string.format("%4u",Register[j].Entity.Variant)
  end
Isaac.ConsoleOutput(#SaveData)
Isaac.ConsoleOutput("\n")
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
  end
  --NewStage
  local level = game:GetLevel()
  if CurStage ~= level:GetStage() then
    Register={}
  end
  CurStage = level:GetStage()
  SpawnRegister()
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
     entity.SpriteOffset = Vector(0,4)
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
    
    if entity.State== BeggarState.IDLE then
      if entity.StateFrame == 0 then
        sprite:Play("Idle", false)
      end
      
      if (entity.Position - player.Position):Length() <= entity.Size + player.Size then --Collision between beggar and player
        if entity.Variant == 0 and player:GetNumCoins() > 0 then
          sound:Play(SoundEffect.SOUND_SCAMPER, 1, 0, false,1)
          player:AddCoins(-1)
          --No need to check a RNG since it's 100% chance
          entity.State = BeggarState.PAYPRIZE
          entity.StateFrame = -1
          
        --if entity.Variant = 1 then give another boost
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
        if entity.Variant == 0 then
          --reward
          player:AddCoins(10)
          entity:GetData().Payout = true 
        end
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


function BlessingAltars:onBeggarDamage(target, dmg, flag, source, countdown)
  return false
end
BlessingAltars:AddCallback(ModCallbacks.MC_NPC_UPDATE,BlessingAltars.onBeggarDamage, BlessingAltars.ENTITY_BEGGAR)

BlessingAltars:onRoom()
BlessingAltars:onLevel()