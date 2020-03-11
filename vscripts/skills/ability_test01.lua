ability_test01 = class({})
print("hello world")
-- modifer name , file path
LinkLuaModifier("modifier_test01", "skills/ability_test01", LUA_MODIFIER_MOTION_NONE)
function ability_test01:OnSpellStart()
	--local caster = self.
	local caster = self:GetCaster();
	local target = self:GetCursorTarget();
	local damage = self:GetSpecialValueFor("damage");
	local stuntime = self:GetSpecialValueFor("stun_time");
	

	local pid = caster:GetPlayerOwnerID();
	-- if PlayerResource:GetCustomTeamAssignment(pid)==9 then
	-- 	PlayerResource:SetCustomTeamAssignment(pid,8);
	-- else
	-- 	PlayerResource:SetCustomTeamAssignment(pid,9);
	-- end
	--print(caster:GetAbsOrigin());
	print("teamid:" .. PlayerResource:GetCustomTeamAssignment(pid));
	--caster:SetTeam(9);
	
	local pos = caster:GetCursorPosition();
	DebugDrawText(pos,"debug text",true,4);
	
-- 	local damagetable = {
-- 	victim = target,
-- 	attacker = caster,
-- 	damage = damage,
-- 	damage_type = DAMAGE_TYPE_MAGICAL
-- }
-- 	ApplyDamage(damagetable);
-- 	target:AddNewModifier(caster, self, "modifier_test01", {duration = stuntime})

-- 	local paticle = "particles/units/heroes/hero_ogre_magi/ogre_magi_fireblast.vpcf";
-- 	ParticleManager:CreateParticle(paticle, PATTACH_OVERHEAD_FOLLOW, target);
-- 	paticle = "particles/units/heroes/hero_ogre_magi/ogre_magi_fireblast_cast.vpcf";
-- 	ParticleManager:CreateParticle(paticle, PATTACH_OVERHEAD_FOLLOW, target);

-- 	caster:EmitSound("test01");
end



modifier_test01 = class({})
function modifier_test01:IsDebuff()
	return true
end

function modifier_test01:IsStunDebuff()
	return true
end

function modifier_test01:CheckState()
	local state = {
	--[MODIFIER_STATE_ROOTED] = true,
	[MODIFIER_STATE_STUNNED] = true,
}
	return state
end

function modifier_test01:DeclareFunctions()
	local funcs = {
	MODIFIER_PROPERTY_OVERRIDE_ANIMATION
}
	return funcs

end

function modifier_test01:GetEffectName()
	return "particles/generic_gameplay/generic_stunned.vpcf";
end

function modifier_test01:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW;
end

function modifier_test01:GetOverrideAnimation(params)
	return ACT_DOTA_DISABLED;
end


function damage(dict)
	local caster = dict.caster;
	local target = dict.target;
	local damage = caster:GetAgility() * 100;

	local pos = caster.GetCursorPosition();
	DrawDebugText(pos,"debug text",true,4);
end