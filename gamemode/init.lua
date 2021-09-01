AddCSLuaFile("cl_init.lua")
AddCSLuaFile("cl_inventory.lua")
AddCSLuaFile("cl_commands.lua")
AddCSLuaFile("cl_gasmask.lua")
AddCSLuaFile("cl_hud.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("sh_gasmask.lua")
AddCSLuaFile("panel/mvsa_panel.lua")
AddCSLuaFile("config.lua")
util.AddNetworkString("mvsa_character_creation")
util.AddNetworkString("mvsa_character_deletion")
util.AddNetworkString("mvsa_character_selection")
util.AddNetworkString("mvsa_character_selected")
util.AddNetworkString("mvsa_character_information")
util.PrecacheModel( "models/half-dead/metroll/p_mask_1.mdl" )
sql.Query("CREATE TABLE IF NOT EXISTS mvsa_player_character( SteamID64 BIGINT NOT NULL, Faction BOOL, RPName VARCHAR(45), ModelIndex TINYINT, Size SMALLINT NOT NULL, Skin TINYINT, BodyGroups VARCHAR(60), GasMaskSet BOOL, PrimaryWep TINYINT, SecondaryWep TINYINT, Launcher TINYINT, Pant TINYINT, Jacket TINYINT, Vest TINYINT, Rucksack TINYINT, Helmet TINYINT, NVG TINYINT, Inventory VARCHAR(60) )")
include("sv_commands.lua")
include("sv_gasmask.lua")
include("shared.lua")
include("sh_gasmask.lua")
include("config.lua")

local function CheckData(ply)
    local data = sql.Query(" SELECT * FROM mvsa_player_character WHERE SteamID64 = " .. tostring(ply:SteamID64()))

    if not data then
        net.Start("mvsa_character_creation")
        net.Send(ply)
    else
        net.Start("mvsa_character_selection")
        net.WriteUInt(#data, 5)

        for k, v in pairs(data) do
            net.WriteUInt(tonumber(v["Faction"]), 1)
            net.WriteString(v["RPName"])
            net.WriteUInt(tonumber(v["ModelIndex"]), 5)
            net.WriteUInt(tonumber(v["Size"]), 8)
            net.WriteUInt(tonumber(v["Skin"]), 5)
            net.WriteString(v["BodyGroups"])
            net.WriteUInt(tonumber(v["GasMaskSet"]), 1)
        end

        net.Send(ply)
    end
end

function RunClass(ply)
    player_manager.SetPlayerClass(ply, "player_" .. string.lower(ply.Faction))
    player_manager.RunClass(ply, "Loadout")
    ply:Spawn()
end

function GM:PlayerInitialSpawn(ply, transition)
    player_manager.SetPlayerClass(ply, "player_spectator")
    CheckData(ply)
    ply:AllowFlashlight(true)
end

function GM:PlayerSpawn(ply, transition)
    if player_manager.GetPlayerClass(ply) == "player_spectator" then
        local view_ent = ents.FindByName("spectator_view")[1]
        ply:SetViewEntity(view_ent)
    else
        ply:SetViewEntity(ply)
        ply:SetModel(MVSA[ply.Faction][ply.ModelIndex][1])
        ply:SetModelScale(ply.Size / 180, 0)
        ply:SetSkin(ply.Skin)

        for k, v in pairs(ply.BodyGroups) do
            ply:SetBodygroup(k - 1, v)
        end

        ply:SetupHands() -- Create the hands and call GM:PlayerSetHandsModel
    end
end

net.Receive("mvsa_character_information", function(len, ply)
    ply.Faction = net.ReadBit()
    ply.RPName = net.ReadString()
    ply.ModelIndex = net.ReadUInt(5)
    ply.Size = net.ReadUInt(8)
    ply.Skin = net.ReadUInt(5)
    ply.BodyGroups = net.ReadString()
    ply:SetNWBool( "GasMaskSet", false )
    ply:SetNWInt( "PrimaryWep", 0 )
    ply:SetNWInt( "SecondaryWep", 0 )
    ply:SetNWInt( "Launcher", 0 )
    ply:SetNWInt( "Pant", 2 )
    ply:SetNWInt( "Jacket", 0 )
    ply:SetNWInt( "Vest", 0 )
    ply:SetNWInt( "Rucksack", 0 )
    ply:SetNWInt( "Helmet", 0 )
    ply:SetNWInt( "NVG", 0 )

    ply.Inventory = {}
    for k = 1,20 do
        ply:SetNWInt( "Inventory" .. tostring(k), 0 )
        ply.Inventory[k] = 0
    end

    sql.Query("INSERT INTO mvsa_player_character VALUES( " .. ply:SteamID64() .. ", " .. tostring(ply.Faction) .. ", " .. SQLStr(ply.RPName) .. ", " .. tostring(ply.ModelIndex) .. ", " .. tostring(ply.Size) .. ", " .. tostring(ply.Skin) .. ", '" .. ply.BodyGroups .. "', 0, 0, 0, 0, 2, 0, 0, 0, 0, 0, '0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0')")
    ply.BodyGroups = string.Split(ply.BodyGroups, ",")

    if ply.Faction == 1 then
        ply.Faction = "Survivor"
    else
        ply.Faction = "USMC"
    end

    RunClass(ply)
end)

net.Receive("mvsa_character_deletion", function(len, ply)
    local rpname = net.ReadString()
    sql.Query("DELETE FROM mvsa_player_character WHERE SteamID64 = " .. tostring(ply:SteamID64()) .. " AND RPName = " .. "'" .. rpname .. "'")
end)

net.Receive("mvsa_character_selected", function(len, ply)
    ply.RPName = net.ReadString()
    local Character = sql.QueryRow("SELECT * FROM mvsa_player_character WHERE SteamID64 = " .. tostring(ply:SteamID64()) .. " AND RPName = " .. "'" .. ply.RPName .. "'")

    if Character.Faction == "1" then
        Character.Faction = "Survivor"
    else
        Character.Faction = "USMC"
    end

    ply.Faction = Character.Faction
    ply.ModelIndex = tonumber(Character.ModelIndex)
    ply.Size = tonumber(Character.Size)
    ply.Skin = tonumber(Character.Skin)
    ply.BodyGroups = string.Split(Character.BodyGroups, ",")
    ply:SetNWBool( "GasMaskSet", Character.GasMaskSet == "1" )
    ply:SetNWInt( "PrimaryWep", tonumber(Character.PrimaryWep) )
    ply:SetNWInt( "SecondaryWep", tonumber(Character.SecondaryWep) )
    ply:SetNWInt( "Launcher", tonumber(Character.Launcher) )
    ply:SetNWInt( "Pant", tonumber(Character.Pant) )
    ply:SetNWInt( "Jacket", tonumber(Character.Jacket) )
    ply:SetNWInt( "Vest", tonumber(Character.Vest) )
    ply:SetNWInt( "Rucksack", tonumber(Character.Rucksack) )
    ply:SetNWInt( "Helmet", tonumber(Character.Helmet) )
    ply:SetNWInt( "NVG", tonumber(Character.NVG) )

    Character.Inventory = string.Split(Character.Inventory, ",")
    ply.Inventory = {}
    for k = 1,20 do
        ply:SetNWInt( "Inventory" .. tostring(k), tonumber(Character.Inventory[k]) )
        ply.Inventory[k] = tonumber(Character.Inventory[k])
    end

    for k, v in pairs(ply.Inventory) do
        if v == 1 then
            ply.GasMaskEquiped = true
            break
        end
    end

    RunClass(ply)
end)

function GM:PlayerSelectSpawn(ply, transition)
    if ply.Faction == "USMC" then
        local spawns = ents.FindByClass("info_player_usmc")
        local random_entry = math.random(#spawns)

        return spawns[random_entry]
    elseif ply.Faction == "Survivor" then
        local spawns = ents.FindByClass("info_player_survivor")
        local random_entry = math.random(#spawns)

        return spawns[random_entry]
    end
end

hook.Add("GasMaskNeeded", "TestTeleportHook", function()
    if player_manager.GetPlayerClass(ACTIVATOR) ~= "player_spectator" then
        local d = DamageInfo()
        d:SetDamage( 1 )
        d:SetAttacker( ACTIVATOR )
        d:SetDamageType( DMG_NERVEGAS )

        ACTIVATOR:TakeDamageInfo( d )
    end
end)

function GM:AllowPlayerPickup( ply, ent )
    print("hello")
    if ent.Category == "Inventory" then
        for k,v in pairs(ply.Inventory) do
            if v == 0 then
                ply.Inventory[k] = ent.ID
                ply:SetNWInt( "Inventory" .. tostring(k), ent.ID )
                local Inventory = table.concat(ply.Inventory, ",")
                sql.Query("UPDATE mvsa_player_character SET Inventory = '" .. Inventory .. "' WHERE SteamID64 = " .. tostring(activator:SteamID64()) .. " AND RPName = " .. "'" .. activator.RPName .. "'")
                print( "it worked!")
                break
            end
        end
    else
        if ply:GetNWInt( ent.Category ) == 0 then
            ply:SetNWInt( ent.Category, ent.ID )
            sql.Query("UPDATE mvsa_player_character SET " .. ent.Category .. " = '" .. tostring(ent.ID) .. "' WHERE SteamID64 = " .. tostring(activator:SteamID64()) .. " AND RPName = " .. "'" .. activator.RPName .. "'")
            print( "it worked!")
        end
    end
end