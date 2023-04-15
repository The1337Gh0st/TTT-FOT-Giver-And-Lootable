if engine.ActiveGamemode() ~= "terrortown" then return end
local modActiveCvar = CreateConVar("ttt_floor_weapons_giver", "1", nil, "Whether this mod is active or not", 0, 1)

local giverCvar = CreateConVar("ttt_floor_weapons_giver_active", "1", {FCVAR_NOTIFY}, "Whether to give weapons to players at the start of a round", 0, 1)

local giveDelayCvar = CreateConVar("ttt_floor_weapons_giver_delay", "0.2", {FCVAR_NOTIFY}, "Seconds after a round starts until floor weapons are given to players that don't have one", 0.2)


local spawnCvar = CreateConVar("ttt_floor_weapons_spawner_active", "1", {FCVAR_NOTIFY}, "If a map has few or no guns, whether floor weapons are automatically spawned on the ground", 0, 1)

local spawnDelayCvar = CreateConVar("ttt_floor_weapons_spawner_delay", "0.2", {FCVAR_NOTIFY}, "Seconds after everyone respawns for the next round, weapons are spawned on the ground", 0.2)

local gunSpawnCvar = CreateConVar("ttt_floor_weapons_spawner_guns", "8", {FCVAR_NOTIFY}, "How many guns are spawned on the ground per player, if the limit is never reached", 0)

local entityLimitCvar = CreateConVar("ttt_floor_weapons_spawner_limit", "350", {FCVAR_NOTIFY}, "How many weapons can be on the map before guns stop being spawned, this includes existing guns already on the map", 0)

-- Gives ammo to a player's gun equivalent to ammo boxes, without going over TTT's reserve ammo limits

local entityCount = 0

local function PlaceWeapon(swep, pos)
    if entityCount >= entityLimitCvar:GetInt() then return end
    local cls = swep and WEPS.GetClass(swep)
    if not cls then return end
    -- Create the weapon, somewhat in the air in case the spot hugs the ground.
    local ent = ents.Create(cls)
    pos.z = pos.z + 3
    ent:SetPos(pos)
    ent:SetAngles(VectorRand():Angle())
    ent:Spawn()
    entityCount = entityCount + 1

end

local spawnPoints = {}


local firstRound = true
local autoSpawnPistols = {}
local autoSpawnHeavyWeps = {}
local ammoGuns = {}
ammoGuns.item_ammo_357_ttt = {}
ammoGuns.item_ammo_pistol_ttt = {}
ammoGuns.item_ammo_revolver_ttt = {}
ammoGuns.item_ammo_smg1_ttt = {}
ammoGuns.item_box_buckshot_ttt = {}
ammoGuns.none = {}
local floorWeapons = {}
local mapEntityCount = 0
local ammoCount = 0
local gunCount = 0
local ammoGunRatio = 1
local floorWeaponPositions = {}

hook.Add("TTTPrepareRound", "FWGGetSpawnPoints", function()
    timer.Simple(0.1, function()
        -- Only runs once a map at the start of the first round
        if firstRound then
            -- Getting the list of all spawnable weapons
            for k, v in pairs(weapons.GetList()) do
                if v and v.AutoSpawnable and v.Base == "weapon_ttt_fof_base" and (not WEPS.IsEquipment(v)) then
                    table.insert(floorWeapons, v)
                end
            end

            -- Getting the lists of specific types of weapons
        --    for i, swep in ipairs(floorWeapons) do
         --       if swep.Kind == WEAPON_PISTOL then
         --           table.insert(autoSpawnPistols, swep)
          --      elseif swep.Kind == WEAPON_HEAVY then
          --          table.insert(autoSpawnHeavyWeps, swep)
          --      end
				
				for i, swep in ipairs(floorWeapons) do
            if swep.AutoSpawnable and swep.Base == "weapon_ttt_fof_base" then
                if swep.IsTwoHandedGun then
					table.insert(autoSpawnHeavyWeps, swep)
                elseif not swep.IsTwoHandedGun then
					table.insert(autoSpawnPistols, swep)
                end
            end


            -- Getting the number of weapons and ammo the map already has
            for _, ent in ipairs(ents.GetAll()) do
                if ent.AutoSpawnable then
                    mapEntityCount = mapEntityCount + 1
                    floorWeaponPositions[ent:GetPos()] = ent.AmmoEnt

                    -- Count the number of ammo boxes and guns in case a map has guns but not enough ammo
                        gunCount = gunCount + 1
                    end
              end
                end

            -- Just to avoid dividing by zero
            if gunCount == 0 then
                gunCount = 1
            end

            ammoGunRatio = ammoCount / gunCount
            firstRound = false
        end


    entityCount = mapEntityCount

    -- Use all "info_player_" ents as spawn points for weapons, as they include entities that are very likely inside a playable area.
    -- E.g. player spawn points
    for _, ent in pairs(ents.FindByClass("info_player_*")) do
        spawnPoints[ent:GetPos()] = true
    end

    -- Get the positions of players from round prep to begin to find potential gun spawn points inside the map
    timer.Create("FWGGetSpawnPoints", 1, 0, function()
        for _, ply in ipairs(player.GetAll()) do
            local pos = ply:GetPos()

            if ply:Alive() and not ply:IsSpec() and ply:OnGround() then
                spawnPoints[pos] = true
            end
        end
    end)

    -- Spawning guns and ammo on the ground
    timer.Create("FWGSpawnWeapons", spawnDelayCvar:GetFloat(), 1, function()
        if not modActiveCvar:GetBool() or not spawnCvar:GetBool() then return end

        -- Spawning guns on the ground if the entity limit hasn't been reached
        local playerCount = 0

        for _, ply in ipairs(player.GetAll()) do
            if ply:Alive() and not ply:IsSpec() then
                playerCount = playerCount + 1
            end
        end

        local spawnCap = gunSpawnCvar:GetInt() * playerCount
        local spawnCount = 0

        for pos, _ in RandomPairs(spawnPoints) do
            if spawnCount >= spawnCap or entityCount >= entityLimitCvar:GetInt() then return end
            PlaceWeapon(table.Random(floorWeapons), pos)
            spawnCount = spawnCount + 1
        end
            end)
    end)
end)

hook.Add("TTTBeginRound", "FWGGiveWeapons", function()
    timer.Remove("FWGGetSpawnPoints")

    -- Giving floor weapons to players
    timer.Create("FWGGiveWeapons", giveDelayCvar:GetFloat(), 1, function()
        if not modActiveCvar:GetBool() or not giverCvar:GetBool() or (Randomat and isfunction(Randomat.IsEventActive) and Randomat:IsEventActive("murder")) then return end

        for i, ply in ipairs(player.GetAll()) do
            local hasPistol = false
            local hasHeavy = false

            for j, wep in ipairs(ply:GetWeapons()) do
                if wep.Kind == WEAPON_PISTOL then
                    hasPistol = true
                elseif wep.Kind == WEAPON_HEAVY then
                    hasHeavy = true
                end
            end

            if not hasPistol then
                local randWepPistol = autoSpawnPistols[math.random(1, #autoSpawnPistols)]
                ply:Give(randWepPistol.ClassName)
            end

            if not hasHeavy then
                local randWepHeavy = autoSpawnHeavyWeps[math.random(1, #autoSpawnHeavyWeps)]
                ply:Give(randWepHeavy.ClassName)
            end
        end
    end)
end)

-- Stopping floor weapons from being given if the round ends before they are given
hook.Add("TTTEndRound", "FWGStopWeapons", function()
    timer.Remove("FWGGiveWeapons")
    timer.Remove("FWGSpawnWeapons")
end)
