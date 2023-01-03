CreateConVar("ttt_lootable_only_appropriate_props",1,bit.bor(FCVAR_NOTIFY,FCVAR_ARCHIVE),"Items can only be dropped from appropiate props like crates, drawers and drums.")

CreateConVar("ttt_lootable_max_items_per_prop",1,bit.bor(FCVAR_NOTIFY,FCVAR_ARCHIVE),"The maximum number of items that can be dropped per prop.")

CreateConVar("ttt_lootable_enabled",1,bit.bor(FCVAR_NOTIFY,FCVAR_ARCHIVE),"If set to 1, the TTT Lootable addon is enabled.")

CreateConVar("ttt_lootable_drop_chance",33,bit.bor(FCVAR_NOTIFY,FCVAR_ARCHIVE),"The percentage chance for a prop to drop an item upon breaking it. ( 0 - 100)")

hook.Add("InitPostEntity","TTT_Lootable_Init",


function()
    
    local a={}
    local b={}
    local c=weapons.GetList()
    local d=weapons.GetList()
    
    for e,f in pairs(c) do 
      if f.Base and f.Base=="weapon_ttt_fof_base"and f.AutoSpawnable then 
        table.insert(b,f.ClassName)
      end 
    end
    
    for e,f in pairs(d) do 
      if f.Base and f.Base=="weapon_ttt_fof_base"and f.AutoSpawnable then 
        table.insert(b,f.ClassName)
      end 
    end
    
    local function g(h)
      return 
      string.find(h,"drum") or string.find(h,"crate") or string.find(h,"box") or string.find(h,"cardboard") or string.find(h,"drawer") or string.find(h,"closet")
	  end
    
    local function i(j,k) if not(util.PointContents(j)==CONTENTS_SOLID) and (not IsValid(k) or IsValid(k:GetPhysicsObject()) and k:GetPhysicsObject():IsMotionEnabled()) then 
        local l;
        if math.random(1,100) <= 100 then 
          l=table.Random(b)
        else l=table.Random(a)end

        
        local m=ents.Create(l) if IsValid(m) then 
          m:SetPos(j)
          m:SetAngles(Angle(math.random(0,360),math.random(0,360),0))
          m:SetCollisionGroup(COLLISION_GROUP_WEAPON)
          m:Spawn()
          
          if IsValid(k) and IsValid(k:GetPhysicsObject()) and IsValid(m:GetPhysicsObject()) then 
            m:GetPhysicsObject():SetVelocity(k:GetVelocity()+VectorRand()*100) end
        end 
      end 
    end
    
    hook.Add("PropBreak","TTT_Lootable_PropBreak",function(n,k)
        if GetConVar("ttt_lootable_enabled"):GetBool() == false then return end
        
        if math.random(1,100) <= GetConVar("ttt_lootable_drop_chance"):GetInt() and (GetConVar("ttt_lootable_only_appropriate_props"):GetBool() 
            and g(string.lower(k:GetModel())) or true) then 
          for o = 1,math.max(1,math.random(-5,GetConVar("ttt_lootable_max_items_per_prop"):GetInt())) do i(k:LocalToWorld(k:OBBCenter()),k)
end
end 
end)
end)
