ability_rand_01 = class({})


function ability_rand_01:OnSpellStart()
	--local caster = self.
	local caster = self:GetCaster();
	local pos = self:GetCursorPosition();
	local loc = caster:GetAbsOrigin();
	
	--SetForwardVector
	--print(diff);
end