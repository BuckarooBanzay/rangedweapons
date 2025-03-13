
----
---- gun_funcs
----

local function update_ammo_counter_on_gun(gunMeta)
	gunMeta:set_string("count_meta", tostring(gunMeta:get_int("RW_bullets")))
end

function rangedweapons.eject_shell(itemstack,player,rld_item,rld_time,rldsound,shell)
	itemstack:set_name(rld_item)
    local meta = player:get_meta()
    meta:set_float("rw_cooldown", rld_time)

    local gunMeta = itemstack:get_meta()
    local bulletStack = ItemStack({name = gunMeta:get_string("RW_ammo_name")})

    local pos = player:get_pos()
    minetest.sound_play(rldsound, {pos = pos}, true)
    local dir = player:get_look_dir()
    local yaw = player:get_look_horizontal()
    if pos and dir and yaw then
        pos.y = pos.y + 1.6
        local obj = minetest.add_entity(pos, "rangedweapons:empty_shell")

        if bulletStack ~= "" then
            local AmmoCaps = bulletStack:get_definition().RW_ammo_capabilities

            local bullet_shell_visual = "wielditem"
            local bullet_shell_texture = "rangedweapons:shelldrop"

            bullet_shell_visual = AmmoCaps.shell_visual or "wielditem"
            bullet_shell_texture = AmmoCaps.shell_texture or "rangedweapons:shelldrop"

            obj:set_properties({textures = {bullet_shell_texture}})
            obj:set_properties({visual = bullet_shell_visual})
        end

        if obj then
            obj:set_velocity({x=dir.x*-10, y=dir.y*-10, z=dir.z*-10})
            obj:set_acceleration({x=dir.x*-5, y=-10, z=dir.z*-5})
            obj:set_yaw(yaw - math.pi/2)
        end
    end
end

function rangedweapons.launch_projectile(player,projNum,projDmg,projEnt,visualType,texture,shoot_sound,combined_velocity,accuracy,skill_value,ColResult,projCrit,projCritEffc,mobPen,nodePen,has_shell,shellEnt,shellTexture,shellVisual,dps,gravity,door_break,glass_break,bullet_particles,sparks,ignite,size,smokeSize,proj_wear,proj_glow)
    local pos = player:get_pos()
    local dir = player:get_look_dir()
    local yaw = player:get_look_horizontal()
    local svertical = player:get_look_vertical()

    if pos and dir and yaw then
        minetest.sound_play(shoot_sound, {pos = pos, max_hear_distance = 500}, true)
        pos.y = pos.y + 1.45

        if has_shell > 0 and minetest.settings:get_bool("rangedweapons_animate_empty_shells", true) then
            local shl = minetest.add_entity(pos, shellEnt)
            shl:set_velocity({x=dir.x * -10, y=dir.y * -10, z=dir.z * -10})
            shl:set_acceleration({x=dir.x * -5, y= -10, z=dir.z * -5})
            shl:set_rotation({x=0,y=yaw - math.pi/2,z=-svertical})
            shl:set_properties({
            textures = {shellTexture},
            visual = shellVisual,})
        end

        if smokeSize > 0 then
            minetest.add_particle({
                pos = pos,
                velocity = {
                    x=(dir.x*3)+(math.random(-10,10)/10),
                    y=(dir.y*3)+(math.random(-10,10)/10),
                    z=(dir.z*3)+(math.random(-10,10)/10)
                },
                acceleration = {
                    x=dir.x * -3,
                    y=2,
                    z=dir.z * -3
                },
                expirationtime = math.random(5,10)/10,
                size = smokeSize / 2,
                collisiondetection = false,
                vertical = false,
                texture = "tnt_smoke.png",
                glow = 5,
            })
        end

        local projectiles = projNum or 1
        for i=1,projectiles do
            local obj = minetest.add_entity(pos, projEnt)
            local ent = obj:get_luaentity()

            obj:set_properties({
                textures = {texture},
                visual = visualType,
                collisionbox = {-size,-size,-size, size,size,size},
                glow = proj_glow
            })
            ent.owner = player:get_player_name()
            if obj then
                ent.damage = projDmg
                ent.crit = projCrit
                ent.critEffc = projCritEffc
                ent.OnCollision = ColResult
                ent.mobPen = mobPen
                ent.nodePen = nodePen
                ent.dps = dps
                ent.door_break = door_break
                ent.glass_break = glass_break
                ent.skill_value = skill_value
                ent.bullet_particles = bullet_particles
                ent.sparks = sparks
                ent.ignite = ignite
                ent.size = size
                ent.timer = 0 + (combined_velocity/2000)
                ent.wear = proj_wear
                local acc = ((( 100 - accuracy ) / 10) / skill_value ) or 0
                obj:set_velocity({
                    x=dir.x * combined_velocity + math.random(-acc,acc),
                    y=dir.y * combined_velocity + math.random(-acc,acc),
                    z=dir.z * combined_velocity + math.random(-acc,acc)
                })
                obj:set_acceleration({x=0, y=-gravity, z=0})
                obj:set_rotation({
                    x=0,
                    y=yaw - math.pi/2,
                    z=-svertical
                })
            end
        end
    end
end


function rangedweapons.shoot_powergun(itemstack, player)
    if minetest.find_node_near(player:get_pos(), 10,"rangedweapons:antigun_block") then
        minetest.sound_play("rangedweapons_empty", {pos = player:get_pos()}, true)
        minetest.chat_send_player(player:get_player_name(), "" ..core.colorize("#ff0000","Guns are prohibited in this area!"))
        return
    end

    local power_cooldown = 0
    local power_consumption = 0
    local PowerCaps = itemstack:get_definition().RW_powergun_capabilities

    if PowerCaps ~= nil then
        power_cooldown = PowerCaps.power_cooldown or 0
        power_consumption = PowerCaps.power_consumption or 0
    end

    local inv = player:get_inventory()
    local playerMeta = player:get_meta()

    if inv:contains_item("main", "rangedweapons:power_particle "..PowerCaps.power_consumption) and
        playerMeta:get_float("rw_cooldown") <= 0 then
        playerMeta:set_float("rw_cooldown", power_cooldown)

        local OnCollision = function() end

        local power_damage = {fleshy=1}
        local power_sound = "rangedweapons_laser"
        local power_velocity = 20
        local power_accuracy = 100
        local power_cooling = 0
        local power_crit = 0
        local power_critEffc = 1
        local power_mobPen = 0
        local power_nodePen = 0
        local power_durability = 0
        local power_dps = 0
        local power_gravity = 0
        local power_door_breaking = 0
        local power_skill = ""
        local power_skillChance =  0
        local power_ent = "rangedweapons:shot_bullet"
        local power_visual = "wielditem"
        local power_texture = "rangedweapons:shot_bullet_visual"
        local power_glass_breaking = 0
        local power_particles = {}
        local power_sparks = 0
        local power_bomb_ignite = 0
        local power_size = 0
        local power_glow = 20
        local power_projectiles = 1

        if PowerCaps ~= nil then
            power_damage = PowerCaps.power_damage or {fleshy=1}
            power_sound = PowerCaps.power_sound or "rangedweapons_glock"
            power_velocity = PowerCaps.power_velocity or 20
            power_accuracy = PowerCaps.power_accuracy or 100
            power_cooling = PowerCaps.power_cooling or itemstack:get_name()
            power_crit = PowerCaps.power_crit or 0
            power_critEffc = PowerCaps.power_critEffc or 1
            power_projectiles = PowerCaps.power_projectiles or 1
            power_mobPen = PowerCaps.power_mob_penetration or 0
            power_nodePen = PowerCaps.power_node_penetration or 0
            power_durability = PowerCaps.power_durability or 0
            power_dps = PowerCaps.power_dps or 0
            power_gravity = PowerCaps.power_gravity or 0
            power_door_breaking = PowerCaps.power_door_breaking or 0
            OnCollision = PowerCaps.OnCollision or function()end
            power_ent = PowerCaps.power_entity or "rangedweapons:shot_bullet"
            power_visual = PowerCaps.power_visual or "wielditem"
            power_texture = PowerCaps.power_texture or "rangedweapons:shot_bullet_visual"
            power_glass_breaking = PowerCaps.power_glass_breaking or 0
            power_particles = PowerCaps.power_particles or nil
            power_sparks = PowerCaps.has_sparks or 0
            power_bomb_ignite = PowerCaps.ignites_explosives or 0
            power_size = PowerCaps.power_projectile_size or 0.0025
            power_glow = PowerCaps.power_projectile_glow or 20

            if PowerCaps.power_skill ~= nil then
                power_skill = PowerCaps.power_skill[1] or ""
                power_skillChance = PowerCaps.power_skill[2] or 0
            else
                power_skill = ""
                power_skillChance = 0
            end
        end

        if power_skillChance > 0 and power_skill ~= "" then
            rangedweapons.gain_skill(player,power_skill,power_skillChance)
        end

        local skill_value = 1
        if power_skill ~= "" then
            skill_value = playerMeta:get_int(power_skill)/100
        end

        rangedweapons.launch_projectile(player,power_projectiles,power_damage,power_ent,power_visual,power_texture,power_sound,power_velocity,power_accuracy,skill_value,OnCollision,power_crit,power_critEffc,power_mobPen,power_nodePen,0,"","","",power_dps,power_gravity,power_door_breaking,power_glass_breaking,power_particles,power_sparks,power_bomb_ignite,power_size,0,0,power_glow)

        if minetest.settings:get_bool("rangedweapons_gun_wear", true) then
            itemstack:add_wear(65535/power_durability)
        end
        itemstack:set_name(power_cooling)

        inv:remove_item("main", "rangedweapons:power_particle "..PowerCaps.power_consumption)
    end
end


function rangedweapons.shoot_gun(itemstack, player)
    if minetest.find_node_near(player:get_pos(), 10,"rangedweapons:antigun_block") then
        minetest.sound_play("rangedweapons_empty", {pos = player:get_pos()}, true)
        minetest.chat_send_player(player:get_player_name(), "" ..core.colorize("#ff0000","Guns are prohibited in this area!"))
        return
    end

    local gun_cooldown = 0
    local GunCaps = itemstack:get_definition().RW_gun_capabilities
    local gun_ammo_save = 0

    if GunCaps ~= nil then
        gun_cooldown = GunCaps.gun_cooldown or 0
        gun_ammo_save = GunCaps.ammo_saving or 0
    end

    local gunMeta = itemstack:get_meta()
    local playerMeta = player:get_meta()

    if gunMeta:get_int("RW_bullets") > 0 and
        playerMeta:get_float("rw_cooldown") <= 0 then

        playerMeta:set_float("rw_cooldown", gun_cooldown)

        if math.random(1,100) > gun_ammo_save then
            gunMeta:set_int("RW_bullets",gunMeta:get_int("RW_bullets")-1)
        end

        update_ammo_counter_on_gun(gunMeta)

        local OnCollision = function() end

        local bulletStack = ItemStack({name = gunMeta:get_string("RW_ammo_name")})
        local AmmoCaps = bulletStack:get_definition().RW_ammo_capabilities

        local gun_damage = {fleshy=1}
        local gun_sound = "rangedweapons_glock"
        local gun_velocity = 20
        local gun_accuracy = 100
        local gun_cooling = 0
        local gun_crit = 0
        local gun_critEffc = 1
        local gun_projectiles = 1
        local gun_mobPen = 0
        local gun_nodePen = 0
        local gun_shell = 0
        local gun_durability = 0
        local gun_dps = 0
        local gun_gravity = 0
        local gun_door_breaking = 0
        local gun_skill = ""
        local gun_skillChance =  0
        local gun_smokeSize =  0

        local bullet_damage = {fleshy=0}
        local bullet_velocity = 0
        local bullet_ent = "rangedweapons:shot_bullet"
        local bullet_visual = "wielditem"
        local bullet_texture = "rangedweapons:shot_bullet_visual"
        local bullet_crit = 0
        local bullet_critEffc = 0
        local bullet_projMult = 1
        local bullet_mobPen = 0
        local bullet_nodePen = 0
        local bullet_shell_ent = "rangedweapons:empty_shell"
        local bullet_shell_visual = "wielditem"
        local bullet_shell_texture = "rangedweapons:shelldrop"
        local bullet_dps = 0
        local bullet_gravity = 0
        local bullet_glass_breaking = 0
        local bullet_particles = {}
        local bullet_sparks = 0
        local bullet_bomb_ignite = 0
        local bullet_size = 0
        local bullet_glow = 20

        if GunCaps ~= nil then
            gun_damage = GunCaps.gun_damage or {fleshy=1}
            gun_sound = GunCaps.gun_sound or "rangedweapons_glock"
            gun_velocity = GunCaps.gun_velocity or 20
            gun_accuracy = GunCaps.gun_accuracy or 100
            gun_cooling = GunCaps.gun_cooling or itemstack:get_name()
            gun_crit = GunCaps.gun_crit or 0
            gun_critEffc = GunCaps.gun_critEffc or 1
            gun_projectiles = GunCaps.gun_projectiles or 1
            gun_mobPen = GunCaps.gun_mob_penetration or 0
            gun_nodePen = GunCaps.gun_node_penetration or 0
            gun_shell = GunCaps.has_shell or 0
            gun_durability = GunCaps.gun_durability or 0
            gun_dps = GunCaps.gun_dps or 0
            gun_ammo_save = GunCaps.ammo_saving or 0
            gun_gravity = GunCaps.gun_gravity or 0
            gun_door_breaking = GunCaps.gun_door_breaking or 0
            gun_smokeSize = GunCaps.gun_smokeSize or 0

            if GunCaps.gun_skill ~= nil then
                gun_skill = GunCaps.gun_skill[1] or ""
                gun_skillChance = GunCaps.gun_skill[2] or 0
            else
                gun_skill = ""
                gun_skillChance = 0
            end
        end

        if gun_skillChance > 0 and gun_skill ~= "" then
            rangedweapons.gain_skill(player,gun_skill,gun_skillChance)
        end

        if AmmoCaps ~= nil then
            OnCollision = AmmoCaps.OnCollision or function()end
            bullet_damage = AmmoCaps.ammo_damage or {fleshy=1}
            bullet_velocity = AmmoCaps.ammo_velocity or 0
            bullet_ent = AmmoCaps.ammo_entity or "rangedweapons:shot_bullet"
            bullet_visual = AmmoCaps.ammo_visual or "wielditem"
            bullet_texture = AmmoCaps.ammo_texture or "rangedweapons:shot_bullet_visual"
            bullet_crit = AmmoCaps.ammo_crit or 0
            bullet_critEffc = AmmoCaps.ammo_critEffc or 0
            bullet_projMult = AmmoCaps.ammo_projectile_multiplier or 1
            bullet_mobPen = AmmoCaps.ammo_mob_penetration or 0
            bullet_nodePen = AmmoCaps.ammo_node_penetration or 0
            bullet_shell_ent = AmmoCaps.shell_entity or "rangedweapons:empty_shell"
            bullet_shell_visual = AmmoCaps.shell_visual or "wielditem"
            bullet_shell_texture = AmmoCaps.shell_texture or "rangedweapons:shelldrop"
            bullet_dps = AmmoCaps.ammo_dps or 0
            bullet_gravity = AmmoCaps.ammo_gravity or 0
            bullet_glass_breaking = AmmoCaps.ammo_glass_breaking or 0
            bullet_particles = AmmoCaps.ammo_particles or nil
            bullet_sparks = AmmoCaps.has_sparks or 0
            bullet_bomb_ignite = AmmoCaps.ignites_explosives or 0
            bullet_size = AmmoCaps.ammo_projectile_size or 0.0025
            bullet_glow = AmmoCaps.ammo_projectile_glow or 20
        end

        local combined_crit = gun_crit + bullet_crit
        local combined_critEffc = gun_critEffc + bullet_critEffc
        local combined_velocity = gun_velocity + bullet_velocity
        local combined_projNum = math.ceil(gun_projectiles * bullet_projMult)
        local combined_mobPen = gun_mobPen + bullet_mobPen
        local combined_nodePen = gun_nodePen + bullet_nodePen
        local combined_dps = gun_dps + bullet_dps
        local combined_dmg = {}
        local combined_gravity = gun_gravity + bullet_gravity

        for i, gunDmg in pairs(gun_damage) do
            if bullet_damage[i] ~= nil then
                combined_dmg[i] = gun_damage[i] + bullet_damage[i]
            else
                combined_dmg[i] = gun_damage[i]
            end
        end
        for i, bulletDmg in pairs(bullet_damage) do
            if gun_damage[i] == nil then
                combined_dmg[i] = bullet_damage[i]
            end
        end


        local skill_value = 1
        if gun_skill ~= "" then
        skill_value = playerMeta:get_int(gun_skill)/100
        end

        rangedweapons.launch_projectile(player,combined_projNum,combined_dmg,bullet_ent,bullet_visual,bullet_texture,gun_sound,combined_velocity,gun_accuracy,skill_value,OnCollision,combined_crit,combined_critEffc,combined_mobPen,combined_nodePen,gun_shell,bullet_shell_ent,bullet_shell_texture,bullet_shell_visual,combined_dps,combined_gravity,gun_door_breaking,bullet_glass_breaking,bullet_particles,bullet_sparks,bullet_bomb_ignite,bullet_size,gun_smokeSize,0,bullet_glow)

        if minetest.settings:get_bool("rangedweapons_gun_wear", true) then
            itemstack:add_wear(65535/gun_durability)
        end
        itemstack:set_name(gun_cooling)
    end
end


function rangedweapons.yeet(itemstack, player)
    if minetest.find_node_near(player:get_pos(), 10,"rangedweapons:antigun_block") then
       minetest.chat_send_player(player:get_player_name(), "" ..core.colorize("#ff0000","throwable weapons are prohibited in this area!"))
       return
    end

    local ThrowCaps = itemstack:get_definition().RW_throw_capabilities
    local playerMeta = player:get_meta()

    local throw_cooldown = 0
    if ThrowCaps ~= nil then
        throw_cooldown = ThrowCaps.throw_cooldown or 0
    end

    if playerMeta:get_float("rw_cooldown") <= 0 then
        playerMeta:set_float("rw_cooldown", throw_cooldown)

        local throw_damage = {fleshy=1}
        local throw_sound = "rangedweapons_throw"
        local throw_velocity = 20
        local throw_accuracy = 100
        local throw_cooling = 0
        local throw_crit = 0
        local throw_critEffc = 1
        local throw_mobPen = 0
        local throw_nodePen = 0
        local throw_dps = 0
        local throw_gravity = 0
        local throw_door_breaking = 0
        local throw_skill = ""
        local throw_skillChance =  0
        local throw_smokeSize =  0
        local throw_ent = "rangedweapons:shot_bullet"
        local throw_visual = "wielditem"
        local throw_texture = "rangedweapons:shot_bullet_visual"
        local throw_glass_breaking = 0
        local throw_particles = {}
        local throw_sparks = 0
        local throw_bomb_ignite = 0
        local throw_size = 0
        local throw_glow = 0
        local OnCollision = function()end

        if ThrowCaps ~= nil then
            throw_damage = ThrowCaps.throw_damage or {fleshy=1}
            throw_sound = ThrowCaps.throw_sound or "rangedweapons_glock"
            throw_velocity = ThrowCaps.throw_velocity or 20
            throw_accuracy = ThrowCaps.throw_accuracy or 100
            throw_cooling = ThrowCaps.throw_cooling or itemstack:get_name()
            throw_crit = ThrowCaps.throw_crit or 0
            throw_critEffc = ThrowCaps.throw_critEffc or 1
            throw_projectiles = ThrowCaps.throw_projectiles or 1
            throw_mobPen = ThrowCaps.throw_mob_penetration or 0
            throw_nodePen = ThrowCaps.throw_node_penetration or 0
            throw_dps = ThrowCaps.throw_dps or 0
            throw_gravity = ThrowCaps.throw_gravity or 0
            throw_door_breaking = ThrowCaps.throw_door_breaking or 0
            throw_ent = ThrowCaps.throw_entity or "rangedweapons:shot_bullet"
            throw_visual = ThrowCaps.throw_visual or "wielditem"
            throw_texture = ThrowCaps.throw_texture or "rangedweapons:shot_bullet_visual"
            throw_glass_breaking = ThrowCaps.throw_glass_breaking or 0
            throw_particles = ThrowCaps.throw_particles or nil
            throw_sparks = ThrowCaps.throw_sparks or 0
            throw_bomb_ignite = ThrowCaps.ignites_explosives or 0
            throw_size = ThrowCaps.throw_projectile_size or 0
            throw_glow = ThrowCaps.throw_projectile_glow or 0
            OnCollision = ThrowCaps.OnCollision or function()end

            if ThrowCaps.throw_skill ~= nil then
                throw_skill = ThrowCaps.throw_skill[1] or ""
                throw_skillChance = ThrowCaps.throw_skill[2] or 0
            else
                throw_skill = ""
                throw_skillChance = 0
            end
        end

        if throw_skillChance > 0 and throw_skill ~= "" then
            rangedweapons.gain_skill(player,throw_skill,throw_skillChance)
        end

        local skill_value = 1
        if throw_skill ~= "" then
            skill_value = playerMeta:get_int(throw_skill)/100
        end

        rangedweapons.launch_projectile(player,throw_projectiles,throw_damage,throw_ent,throw_visual,throw_texture,throw_sound,throw_velocity,throw_accuracy,skill_value,OnCollision,throw_crit,throw_critEffc,throw_mobPen,throw_nodePen,0,"","","",throw_dps,throw_gravity,throw_door_breaking,throw_glass_breaking,throw_particles,throw_sparks,throw_bomb_ignite,throw_size,0,itemstack:get_wear(),throw_glow)
        itemstack:take_item()
    end
end


function rangedweapons.single_load_gun(itemstack, player)
    local GunCaps = itemstack:get_definition().RW_gun_capabilities

    if GunCaps ~= nil then
        gun_unload_sound = GunCaps.gun_unload_sound or ""
    end

    minetest.sound_play(gun_unload_sound, {pos = player:get_pos()}, true)

    local gun_reload = 0.25

    if GunCaps ~= nil then
        gun_reload = GunCaps.gun_reload or 0.25
    end

    local playerMeta = player:get_meta()
    local gunMeta = itemstack:get_meta()

    gunMeta:set_float("RW_reload_delay",gun_reload)

    playerMeta:set_float("rw_cooldown",gun_reload)

    local player_has_ammo = 0
    local clipSize = 0
    local reload_ammo = ""

    if GunCaps.suitable_ammo ~= nil then
    local inv = player:get_inventory()
    for i = 1,inv:get_size("main") do

    for _, ammo in pairs(GunCaps.suitable_ammo) do
    if inv:get_stack("main",i):get_name() == ammo[1] then
    reload_ammo = inv:get_stack("main",i)
    clipSize = ammo[2]

    player_has_ammo = 1
    break
    end end

    if player_has_ammo == 1 then
    break
    end

    end end

    if player_has_ammo == 1 then
        gunMeta = itemstack:get_meta()
        local ammoCount = gunMeta:get_int("RW_bullets")
        local ammoName = gunMeta:get_string("RW_ammo_name")
        local inv = player:get_inventory()

        if ammoName ~= reload_ammo:get_name() then
            inv:add_item("main",ammoName.." "..ammoCount)
            gunMeta:set_int("RW_bullets",0)
        end

        if inv:contains_item("main",reload_ammo:get_name()) and gunMeta:get_int("RW_bullets") < clipSize then
            if not minetest.settings:get_bool("rangedweapons_infinite_ammo", false) then
                inv:remove_item("main",reload_ammo:get_name())
            end
            gunMeta:set_int("RW_bullets",gunMeta:get_int("RW_bullets")+1)
        end

        gunMeta:set_string("RW_ammo_name",reload_ammo:get_name())

        update_ammo_counter_on_gun(gunMeta)

        if GunCaps.gun_unloaded ~= nil then
            itemstack:set_name(GunCaps.gun_unloaded)
        end
    end
end


function rangedweapons.reload_gun(itemstack, player)
    local GunCaps = itemstack:get_definition().RW_gun_capabilities

    local gun_unload_sound = ""
    if GunCaps ~= nil then
       gun_unload_sound = GunCaps.gun_unload_sound or ""
    end

    minetest.sound_play(gun_unload_sound, {pos = player:get_pos()}, true)

    local gun_reload = 0.25

    if GunCaps ~= nil then
        gun_reload = GunCaps.gun_reload or 0.25
    end

    local playerMeta = player:get_meta()
    local gunMeta = itemstack:get_meta()

    gunMeta:set_float("RW_reload_delay",gun_reload)

    playerMeta:set_float("rw_cooldown",gun_reload)

    local player_has_ammo = 0
    local clipSize = 0
    local reload_ammo = ""

    if GunCaps.suitable_ammo ~= nil then
        local inv = player:get_inventory()
        for i = 1,inv:get_size("main") do

            for _, ammo in pairs(GunCaps.suitable_ammo) do
                if inv:get_stack("main",i):get_name() == ammo[1] then
                    reload_ammo = inv:get_stack("main",i)
                    clipSize = ammo[2]
                    player_has_ammo = 1
                    break
                end
            end

            if player_has_ammo == 1 then
                break
            end
        end
    end

    if player_has_ammo == 1 then
        gunMeta = itemstack:get_meta()
        local ammoCount = gunMeta:get_int("RW_bullets")
        local ammoName = gunMeta:get_string("RW_ammo_name")
        local inv = player:get_inventory()

        if minetest.settings:get_bool("rangedweapons_infinite_ammo", false) then
            gunMeta:set_int("RW_bullets",clipSize)
        else
            inv:add_item("main",ammoName.." "..ammoCount)
            if inv:contains_item("main",reload_ammo:get_name().." "..clipSize) then
                inv:remove_item("main",reload_ammo:get_name().." "..clipSize)
                gunMeta:set_int("RW_bullets",clipSize)
            else
                gunMeta:set_int("RW_bullets",reload_ammo:get_count())
                inv:remove_item("main",reload_ammo:get_name().." "..reload_ammo:get_count())
            end
        end
        gunMeta:set_string("RW_ammo_name",reload_ammo:get_name())
        update_ammo_counter_on_gun(gunMeta)

        if GunCaps.gun_magazine ~= nil then
            local pos = player:get_pos()
            local dir = player:get_look_dir()
            local yaw = player:get_look_horizontal()
            if pos and dir and yaw then
                pos.y = pos.y + 1.4
                local obj = minetest.add_entity(pos,"rangedweapons:mag")
                if obj then
                    obj:set_properties({textures = {GunCaps.gun_magazine}})
                    obj:set_velocity({x=dir.x*2, y=dir.y*2, z=dir.z*2})
                    obj:set_acceleration({x=0, y=-5, z=0})
                    obj:set_rotation({x=0,y=yaw - math.pi/2,z=0})
                end
            end
        end

        if GunCaps.gun_unloaded ~= nil then
            itemstack:set_name(GunCaps.gun_unloaded)
        end
    end
end


function rangedweapons.make_sparks(pos)
    minetest.sound_play("rengedweapons_ricochet", {pos = pos, gain = 0.75}, true)
    for i=1,9 do
        minetest.add_particle({
            pos = pos,
            velocity = {
                x=math.random(-6.0,6.0),
                y=math.random(-10.0,15.0),
                z=math.random(-6.0,6.0)
            },
            acceleration = {
                x=math.random(-9.0,9.0),
                y=math.random(-15.0,-3.0),
                z=math.random(-9.0,9.0)
            },
            expirationtime = 1.0,
            size = math.random(1,2),
            collisiondetection = true,
            vertical = false,
            texture = "rangedweapons_spark.png",
            glow = 25
        })
    end
end

local max_gun_efficiency = tonumber(minetest.settings:get("rangedweapons_max_gun_efficiency")) or 300

function rangedweapons.gain_skill(player,skill,chance)
    if math.random(1, chance) == 1 then
        local p_meta = player:get_meta()
        local skill_num = p_meta:get_int(skill)
        if skill_num < max_gun_efficiency then
            p_meta:set_int(skill, skill_num + 1)
            minetest.chat_send_player(player:get_player_name(), "" ..core.colorize("#25c200","You've improved your skill with this type of gun!"))
        end
    end
end
