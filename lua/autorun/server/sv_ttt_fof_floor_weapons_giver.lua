if engine.ActiveGamemode() == "terrortown" and SERVER then
    CreateConVar("ttt_floor_weapons_giver", "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Whether floor weapons are automatically given at the start of a round if a player doesn't have one", 0, 1)

    CreateConVar("ttt_floor_weapons_giver_delay", "0", {FCVAR_ARCHIVE, FCVAR_NOTIFY}, "How long after a round starts until floor weapons are given to players that don't have one", 0)

    local autoSpawnPistols = {}
    local autoSpawnHeavyWeps = {}

    -- Getting the list of all pistol and heavy floor weapons, only runs once a map at the start of the first round
    hook.Add("TTTPrepareRound", "FWGGetWeaponsList", function()
        for i, swep in ipairs(weapons.GetList()) do
            if swep.AutoSpawnable and swep.Base == "weapon_ttt_fof_base" then
                if swep.IsTwoHandedGun then
					table.insert(autoSpawnHeavyWeps, swep)
                elseif not swep.IsTwoHandedGun then
					table.insert(autoSpawnPistols, swep)
                end
            end
        end

        hook.Remove("TTTPrepareRound", "FWGGetWeaponsList")
    end)

    -- Giving floor weapons to anyone who doesn't have any after the round starts, after the configured delay
    hook.Add("TTTBeginRound", "FWGGiveWeapons", function()
        timer.Create("FWGGiveWeapons", GetConVar("ttt_floor_weapons_giver_delay"):GetFloat(), 1, function()
            if GetConVar("ttt_floor_weapons_giver"):GetBool() then
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
            end
        end)
    end)

    -- Stopping floor weapons from being given if the round ends before they are given
    hook.Add("TTTEndRound", "FWGStopWeapons", function(win)
        timer.Remove("FWGGiveWeapons")
    end)
end
