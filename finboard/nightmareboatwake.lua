local assets =
{
	Asset( "ANIM", "anim/nightmareboat_wake_trail.zip" ),
}

local function fn(Sim)
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
    local anim = inst.entity:AddAnimState()
    anim:SetBuild("nightmareboat_wake_trail")
   	anim:SetBank( "wakeTrail" )
   	anim:SetOrientation( ANIM_ORIENTATION.OnGround )
	anim:SetLayer(LAYER_BACKGROUND )
	anim:SetSortOrder( 3 )
	anim:PlayAnimation( "trail" ) 
	--inst:Hide()
	inst:AddTag( "FX" )
	inst:AddTag( "NOCLICK" )
	inst:ListenForEvent( "animover", function(inst) inst:Remove() end )

	inst:AddComponent("colourtweener")
	inst.components.colourtweener:StartTween({0,0,0,0}, FRAMES*20)

    return inst
end

return Prefab( "common/fx/nightmareboat_wake", fn, assets ) 
 
