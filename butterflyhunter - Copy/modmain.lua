
local EQUIPSLOTS = GLOBAL.EQUIPSLOTS
local distsq = GLOBAL.distsq
local TheSim = GLOBAL.TheSim

if TheSim:GetGameID()=="DS" then
-----------------------------------
-- Component mod example
--
--  AddComponentPostInit("componentname", initfn)
--        Use this to modify a component's properties or behavior
-----------------------------------
    local function TargetButterfliesDS(component)
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
    AddComponentPostInit("playercontroller", TargetButterfliesDS)

elseif TheSim:GetGameID()=="DST" then

    local CanEntitySeeTarget = GLOBAL.CanEntitySeeTarget
    local CONTROL_ATTACK = GLOBAL.CONTROL_ATTACK

    local function ValidateAttackTarget(combat, target, force_attack, x, z, has_weapon, reach)
        if not combat:CanTarget(target) then
            return false
        end

        --no combat if light/extinguish target
        local targetcombat = target.replica.combat
        if targetcombat ~= nil then
            if combat:IsAlly(target) then
                return false
            elseif not (force_attack or
                        combat:IsRecentTarget(target) or
                        targetcombat:GetTarget() == combat.inst) then
                --must use force attack non-hostile creatures
                if not (target:HasTag("hostile") or
                        (has_weapon and target:HasTag("monster") or
                        target:HasTag("butterfly") and not target:HasTag("player"))) then
                    return false
                end
                --must use force attack on players' followers
                local follower = target.replica.follower
                if follower ~= nil then
                    local leader = follower:GetLeader()
                    if leader ~= nil and
                        leader:HasTag("player") and
                        leader.replica.combat:GetTarget() ~= combat.inst then
                        return false
                    end
                end
            end
        end

        --Now we ensure the target is in range
        --light/extinguish targets may not have physics
        reach = target.Physics ~= nil and reach + target.Physics:GetRadius() or reach
        return target:GetDistanceSqToPoint(x, 0, z) <= reach * reach
    end

    local function TargetButterfliesDST(component)
        local original_GetAttackTarget = component.GetAttackTarget
        component.GetAttackTarget = function(self, force_attack, force_target, isretarget)
            if self.inst:HasTag("playerghost") or self.inst.replica.inventory:IsHeavyLifting() then
                return
            end

            local combat = self.inst.replica.combat
            if combat == nil then
                return
            end

            --Don't want to spam the attack button before the server actually starts the buffered action
            if not self.ismastersim and (self.remote_controls[CONTROL_ATTACK] or 0) > 0 then
                return
            end

            if self.inst.sg ~= nil then
                if self.inst.sg:HasStateTag("attack") then
                    return
                end
            elseif self.inst:HasTag("attack") then
                return
            end

            if isretarget and
                combat:CanHitTarget(force_target) and
                force_target.replica.health ~= nil and
                not force_target.replica.health:IsDead() and
                CanEntitySeeTarget(self.inst, force_target) then
                return force_target
            end

            local x, y, z = self.inst.Transform:GetWorldPosition()
            local attackrange = combat:GetAttackRangeWithWeapon()
            local rad = self.directwalking and attackrange or attackrange + 6
            --"not self.directwalking" is autowalking

            --Beaver teeth counts as having a weapon
            local has_weapon = self.inst:HasTag("beaver")
            if not has_weapon then
                local inventory = self.inst.replica.inventory
                local tool = inventory ~= nil and inventory:GetEquippedItem(EQUIPSLOTS.HANDS) or nil
                if tool ~= nil then
                    local inventoryitem = tool.replica.inventoryitem
                    has_weapon = inventoryitem ~= nil and inventoryitem:IsWeapon()
                end
            end

            local reach = self.inst.Physics:GetRadius() + rad + 0.1

            if force_target ~= nil then
                return ValidateAttackTarget(combat, force_target, force_attack, x, z, has_weapon, reach) and force_target or nil
            end

            --To deal with entity collision boxes we need to pad the radius.
            --Only include combat targets for auto-targetting, not light/extinguish
            --See entityreplica.lua (re: "_combat" tag)
            local nearby_ents = TheSim:FindEntities(x, y, z, rad + 5, { "_combat" }, { "INLIMBO" })
            local nearest_dist = math.huge
            isretarget = false --reusing variable for flagging when we've found recent target
            force_target = nil --reusing variable for our nearest target
            for i, v in ipairs(nearby_ents) do
                if ValidateAttackTarget(combat, v, force_attack, x, z, has_weapon, reach) and
                    CanEntitySeeTarget(self.inst, v) then
                    local dsq = self.inst:GetDistanceSqToInst(v)
                    local dist =
                        (dsq <= 0 and 0) or
                        (v.Physics ~= nil and math.max(0, math.sqrt(dsq) - v.Physics:GetRadius())) or
                        math.sqrt(dsq)
                    if not isretarget and combat:IsRecentTarget(v) then
                        if dist < attackrange + .1 then
                            return v
                        end
                        isretarget = true
                    end
                    if dist < nearest_dist then
                        nearest_dist = dist
                        force_target = v
                    end
                elseif not isretarget and combat:IsRecentTarget(v) then
                    isretarget = true
                end
            end
            return force_target
        end
    end

AddComponentPostInit("playercontroller", TargetButterfliesDST)
end