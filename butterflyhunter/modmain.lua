
local EQUIPSLOTS = GLOBAL.EQUIPSLOTS
local distsq = GLOBAL.distsq

-----------------------------------
-- Component mod example
--
--  AddComponentPostInit("componentname", initfn)
--        Use this to modify a component's properties or behavior
-----------------------------------
local function TargetButterflies(component)
    local original_GetAttackTarget = component.GetAttackTarget
    component.GetAttackTarget = function(self, force_attack)
		local x,y,z = self.inst.Transform:GetWorldPosition()
		
		local rad = self.inst.components.combat:GetAttackRange()
		
		
		if not self.directwalking then rad = rad + 6 end --for autowalking
		
		--To deal with entity collision boxes we need to pad the radius.
		local nearby_ents = TheSim:FindEntities(x,y,z, rad + 5)
		local tool = self.inst.components.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
		local has_weapon = tool and tool.components.weapon 
		
		local playerRad = self.inst.Physics:GetRadius()
		
		for k,guy in ipairs(nearby_ents) do

			if guy ~= self.inst and
			   guy:IsValid() and 
			   not guy:IsInLimbo() and
			   not (guy.sg and guy.sg:HasStateTag("invisible")) and
			   guy.components.health and not guy.components.health:IsDead() and 
			   guy.components.combat and guy.components.combat:CanBeAttacked(self.inst) and
			   not (guy.components.follower and guy.components.follower.leader == self.inst) and
			   --Now we ensure the target is in range.
			   distsq(guy:GetPosition(), self.inst:GetPosition()) <= math.pow(rad + playerRad + guy.Physics:GetRadius() + 0.1 , 2) then
				if (guy:HasTag("monster") and has_weapon) or
					guy:HasTag("hostile") or
					guy:HasTag("butterfly") or
					self.inst.components.combat:IsRecentTarget(guy) or
					guy.components.combat.target == self.inst or
					force_attack then
						return guy
				end
			end
		end
    end
end
AddComponentPostInit("playercontroller", TargetButterflies)