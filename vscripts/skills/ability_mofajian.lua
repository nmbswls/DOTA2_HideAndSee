ability_mofajian = class({})
-- modifer name , file path
--LinkLuaModifier("modifier_ability_mofajian", "skills/ability_mofajian", LUA_MODIFIER_MOTION_NONE)
function ability_mofajian:OnSpellStart()
	--local caster = self.
	local caster = self:GetCaster();
	local target = self:GetCursorTarget();

	local playerID = caster:GetPlayerID();
	
	local location = self:GetCursorPosition();

	--caster:SetModel("models/creeps/neutral_creeps/n_creep_gnoll/n_creep_gnoll_frost.vmdl")
	
	--GameRules:ResetToCustomGameSetup();
 	
	if caster.unit then
		print("bind");
	end
	
-- 	local info = {
-- 	EffectName = "particles/units/heroes/hero_vengeful/vengeful_magic_missle.vpcf",
-- 	Ability = self,
-- 	iMoveSpeed = 900,
-- 	Source = target,
-- 	Target = caster,
-- 	iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_HITLOCATION,
-- }	
-- 	ProjectileManager:CreateTrackingProjectile(info);
end

function ability_mofajian:OnProjectileHit(hTarget, vLocation)
	print("hit")
end


--particles\units\heroes\hero_vengeful\vengeful_magic_missle_projectile.vpcf

