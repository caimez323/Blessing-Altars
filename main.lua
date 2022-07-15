--[[
    Hey ! thanks for downloading my mod
    I hope you had/will have fun with this version
    Feel free to check the code here

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

function RemoveFromRegister(entity)
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



BeggarState = {
  IDLE = 0,
  PAYNOTHING = 2,
  PAYPRIZE = 3,
  PRIZE = 4,
  TELEPORT = 5,
}



function BlessingAltars:onBeggar(entity)
    local player = Isaac.GetPlayer(0)
    
    local entity = entity:ToNPC()
    local sprite = entity:GetSprite() --To play animation
    local data = entity:GetData()
    
    
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