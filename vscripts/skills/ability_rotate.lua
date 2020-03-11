ability_rotate = class({})


function ability_rotate:OnSpellStart()
	--local caster = self.
	local caster = self:GetCaster();
	local pos = self:GetCursorPosition();
	local loc = caster:GetAbsOrigin();
	-- if caster.unit then
	-- 	loc = caster.unit:GetAbsOrigin();
	-- 	local diff = pos - loc;
	-- 	caster.unit:SetForwardVector(diff);
	-- end

	
	
	--SetForwardVector
	--print(diff);
end