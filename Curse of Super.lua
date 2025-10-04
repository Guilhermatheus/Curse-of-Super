addHook("PlayerThink", function(player)
	if player.mo.starttrigger or player.bot then return end
	player.mo.starttrigger = true
	if not (player.charflags & SF_SUPER) then player.charflags = $1|SF_SUPER end
	if not emeralds then emeralds = $|EMERALD1|EMERALD2|EMERALD3|EMERALD4|EMERALD5|EMERALD6|EMERALD7 end
	if player.solchar then player.solchar.istransformed = 1
	else player.powers[pw_super] = 1 end
	P_GivePlayerRings(player, 23)
	player.mo.state = S_PLAY_STND
end)

addHook("PlayerThink", function(player)
	if player.bot then return end
	if player.rings <= 0 then P_DamageMobj(player.mo, nil, nil, 0, DMG_INSTAKILL) end
	
	if player.powers[pw_extralife] then player.mo.got1up = true
	else
		if player.mo.got1up == true then
			S_SetMusicPosition(player.mo.storedmusicpos)
			S_SetInternalMusicVolume(0, player)
			S_FadeMusic(100, MUSICRATE, player)
			player.mo.got1up = false
		end
		player.mo.storedmusicpos = S_GetMusicPosition()
	end
	
	if player.powers[pw_invulnerability] > 3 * TICRATE and not player.sparkles then player.sparkles = true end
	if player.powers[pw_invulnerability] <= 1 and player.sparkles then player.sparkles = false end
	if player.powers[pw_sneakers] > 1 then
		player.powers[pw_sneakers] = 1
		S_StartSound(mo, sfx_itemup)
		P_GivePlayerRings(player, 10)
	end
	
	if (player.sparkles and player.powers[pw_super]) or stoppedclock or player.pflags & PF_FINISHED then
		if not player.mo.storedrings or player.rings > player.mo.storedrings then player.mo.storedrings = player.rings end
		if player.rings < player.mo.storedrings then player.rings = player.mo.storedrings end
	else player.mo.storedrings = 0 end
end)

addHook("TouchSpecial", function(emeraldtoken, mo)
	if not emeraldtoken.grabbed then return end
	P_GivePlayerRings(mo.player, 25)
	P_AddPlayerScore(mo.player, 1000)
	S_StartSound(mo, sfx_chchng)
	emeraldtoken.grabbed = true
	P_KillMobj(emeraldtoken)
	return true
end, MT_TOKEN)

addHook("MobjDamage", function(target, inflictor, source, damage, damagetype)
	if source and source.player and source.player.sparkles
	and (target.flags & MF_ENEMY) then
		P_GivePlayerRings(source.player, 2)
		S_StartSound(source, sfx_itemup)
	end
	if (target.flags & MF_BOSS) then
		for player in players.iterate
			if player.bot then return end
			if target.type == MT_METALSONIC_BATTLE then P_GivePlayerRings(player, 2) end
			P_GivePlayerRings(player, 5)
			S_StartSound(source, sfx_kc5e)
		end
	end
end)

local function SuperAttract(source, dest)
	local dist = 0
	local ndist = 0
	local speedmul = 0
	local tx = dest.x
	local ty = dest.y
	local tz = dest.z + (dest.height/2)
	local xydist = P_AproxDistance(tx - source.x, ty - source.y)
	if dest and dest.health and dest.valid and dest.type == MT_PLAYER
		source.angle = R_PointToAngle2(source.x, source.y, tx, ty)
		dist = P_AproxDistance(xydist, tz - source.z)
		if (dist < 1)
			dist = 1
		end
		speedmul = P_AproxDistance(dest.momx, dest.momy) + FixedMul(source.info.speed, source.scale)
		source.momx = FixedMul(FixedDiv(tx - source.x, dist), speedmul)
		source.momy = FixedMul(FixedDiv(ty - source.y, dist), speedmul)
		source.momz = FixedMul(FixedDiv(tz - source.z, dist), speedmul)
		ndist = P_AproxDistance(P_AproxDistance(tx - (source.x + source.momx), ty - (source.y+source.momy)), tz - (source.z+source.momz))
		if (ndist > dist)
			source.momx = 0
			source.momy = 0
			source.momz = 0
			P_TeleportMove(source, tx, ty, tz)
		end
	end
end

addHook("MobjThinker", function(ring)
	if (mapheaderinfo[gamemap].typeoflevel & TOL_NIGHTS) then return end
    if ring and ring.valid and ring.health > 0
        local soup
        for p in players.iterate
            if p.mo and p.mo.valid and R_PointToDist2(p.mo.x, p.mo.y, ring.x, ring.y) <= (RING_DIST/6) and abs(ring.z - p.mo.z) < (RING_DIST/6)
                soup = p.mo
            end
        end
        if soup
            local momRing = P_SpawnMobjFromMobj(ring, 0,0,0, MT_FLINGRING)
            momRing.followmo = soup
            P_RemoveMobj(ring)
        end
    end
end, MT_RING)

addHook("MobjThinker", function(ring)
	if (mapheaderinfo[gamemap].typeoflevel & TOL_NIGHTS)
		return
	end
    if ring and ring.valid and ring.health > 0 and ring.followmo and ring.followmo.valid
        if R_PointToDist2(ring.followmo.x, ring.followmo.y, ring.x, ring.y) <= RING_DIST/3 and abs(ring.z - ring.followmo.z) < RING_DIST/3
			SuperAttract(ring, ring.followmo)
        else
            ring.fuse = 5*TICRATE
        end
        if ring.fuse == 2
            P_SpawnMobjFromMobj(ring, 0,0,0, MT_RING)
            P_RemoveMobj(ring)
        end
    end
end, MT_FLINGRING)
