AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.Category = "PrimaryWep"
ENT.WepName = "m9k_acr"
ENT.Ammo = "5.56×45mm NATO"
ENT.ID = 14

function ENT:Initialize()
    LootCount = LootCount + 1
    self:SetModel(self.Model)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    self:PhysWake()
end

function ENT:Use(activator, caller, useType, value)
    if activator:GetNWInt( self.Category ) < 2 then
        LootCount = LootCount - 1
        PickupWep(activator, self)
    end
end