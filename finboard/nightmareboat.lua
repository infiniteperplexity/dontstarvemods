require "prefabutil"

--The test to see if a boat can be built in a certain position is defined in the builder component Builder:CanBuildAtPoint

local prefabs =
{
	"nightmareboat_wake",
	"boat_hit_fx",
	"boat_hit_fx_raft_log",
	"boat_hit_fx_raft_bamboo",
	"boat_hit_fx_rowboat",
	"boat_hit_fx_cargoboat",
	"boat_hit_fx_armoured",
	"flotsam_armoured",
	"flotsam_bamboo",
	"flotsam_cargo",
	"flotsam_lograft",
	"flotsam_rowboat",
	"flotsam_surfboard",
}

local soundprefix = "researchlab"
local name = "researchlab"

local rowboatassets = 
{
	--Asset("ANIM", "anim/researchlab.zip"),
	Asset("ANIM", "anim/rowboat_basic.zip"),
	Asset("ANIM", "anim/nightmareboat_build.zip"),
	Asset("ANIM", "anim/swap_sail.zip"), 
	Asset("ANIM", "anim/swap_lantern_boat.zip"),
	Asset("ANIM", "anim/boat_hud_row.zip"),
	Asset("ANIM", "anim/boat_inspect_row.zip"),
	Asset("ANIM", "anim/flotsam_rowboat_build.zip"),
}

local raftassets = 
{
	Asset("ANIM", "anim/raft_basic.zip"),
	Asset("ANIM", "anim/raft_build.zip"),
	Asset("ANIM", "anim/boat_hud_raft.zip"),
	Asset("ANIM", "anim/boat_inspect_raft.zip"),
	Asset("ANIM", "anim/flotsam_bamboo_build.zip"),
}

local surfboardassets =
{
	Asset("ANIM", "anim/raft_basic.zip"),
	Asset("ANIM", "anim/raft_surfboard_build.zip"),
	Asset("ANIM", "anim/boat_hud_raft.zip"),
	Asset("ANIM", "anim/boat_inspect_raft.zip"),
	Asset("ANIM", "anim/flotsam_surfboard_build.zip"),
	Asset("ANIM", "anim/surfboard.zip"),
	Asset("MINIMAP_IMAGE", "surfboard"),
}

local cargoassets =
{
	Asset("ANIM", "anim/rowboat_basic.zip"),
	Asset("ANIM", "anim/rowboat_cargo_build.zip"),
	Asset("ANIM", "anim/swap_sail.zip"), 
	Asset("ANIM", "anim/swap_lantern_boat.zip"),
	Asset("ANIM", "anim/boat_hud_cargo.zip"),
	Asset("ANIM", "anim/boat_inspect_cargo.zip"),
	Asset("ANIM", "anim/flotsam_cargo_build.zip"),
	Asset("MINIMAP_IMAGE", "cargo"),
}


local armouredboatassets = 
{
	--Asset("ANIM", "anim/researchlab.zip"),
	Asset("ANIM", "anim/rowboat_basic.zip"),
	Asset("ANIM", "anim/rowboat_armored_build.zip"),
	Asset("ANIM", "anim/swap_sail.zip"), 
	Asset("ANIM", "anim/swap_lantern_boat.zip"),
	Asset("ANIM", "anim/boat_hud_row.zip"),
	Asset("ANIM", "anim/boat_inspect_row.zip"),
	Asset("ANIM", "anim/flotsam_armoured_build.zip"),
}

local lograftassets = 
{
	Asset("ANIM", "anim/raft_basic.zip"),
	Asset("ANIM", "anim/raft_log_build.zip"),
	Asset("ANIM", "anim/boat_hud_raft.zip"),
	Asset("ANIM", "anim/boat_inspect_raft.zip"),
	Asset("ANIM", "anim/flotsam_lograft_build.zip"),
}


local function boat_perish(inst)
	if inst.components.drivable.driver then
		local driver = inst.components.drivable.driver
		driver.components.driver:OnDismount(true)
		driver.components.health:Kill("drowning")
		inst.SoundEmitter:PlaySound(inst.sinksound)
		inst:Remove()
	end
end
local function onhit(inst, worker)
	inst.AnimState:PlayAnimation("hit")
	inst.AnimState:PushAnimation("run_loop", true)
end
local function onhammered(inst, worker)
	inst.components.lootdropper:DropLoot()
	SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
	inst.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")
	inst:Remove()
end
local function onmounted(inst)
	inst:RemoveComponent("workable")  
end 
local function ondismounted(inst)
	inst:AddComponent("workable")
	inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)
	inst.components.workable:SetOnWorkCallback(onhit)
end 
local function onopen(inst)
	if inst.components.drivable.driver == nil then
		inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/HUD_boat_inventory_open")
	end
end
local function onclose(inst)
	if inst.components.drivable.driver == nil then
		inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/HUD_boat_inventory_close")
	end
end
local function setupcontainer(inst, slots, bank, build, inspectslots, inspectbank, inspectbuild, inspectboatbadgepos, inspectboatequiproot)
	inst:AddComponent("container")
	inst.components.container:SetNumSlots(#slots)
	inst.components.container.type = "boat"
	inst.components.container.side_align_tip = -500
	inst.components.container.canbeopened = false
	inst.components.container.onopenfn = onopen
	inst.components.container.onclosefn = onclose

	inst.components.container.widgetslotpos = slots
	inst.components.container.widgetanimbank = bank
	inst.components.container.widgetanimbuild = build
	inst.components.container.widgetboatbadgepos = Vector3(0, 40, 0)
	inst.components.container.widgetequipslotroot = Vector3(-80, 40, 0)


	local boatwidgetinfo = {}
	boatwidgetinfo.widgetslotpos = inspectslots
	boatwidgetinfo.widgetanimbank = inspectbank
	boatwidgetinfo.widgetanimbuild = inspectbuild
	boatwidgetinfo.widgetboatbadgepos = inspectboatbadgepos
	boatwidgetinfo.widgetpos = Vector3(200, 0, 0)
	boatwidgetinfo.widgetequipslotroot = inspectboatequiproot
	inst.components.container.boatwidgetinfo = boatwidgetinfo
end 
local function commonfn(Sim)
	local inst = CreateEntity()
	local trans = inst.entity:AddTransform()
	trans:SetFourFaced()
	inst.no_wet_prefix = true 

	inst:AddTag("boat")

	local anim = inst.entity:AddAnimState()
	
	inst.entity:AddSoundEmitter()

	inst.entity:AddPhysics()
	inst.Physics:SetCylinder(0.25,2)

	inst:AddComponent("inspectable")
	inst:AddComponent("drivable")
	
	inst.waveboost = TUNING.WAVEBOOST

	inst.sailmusic = "sailing"

	inst:AddComponent("boathealth")
	inst.components.boathealth:SetDepletedFn(boat_perish)

    inst:AddComponent("workable")
    inst.components.workable:SetWorkAction(ACTIONS.HAMMER)
    inst.components.workable:SetWorkLeft(4)
    inst.components.workable:SetOnFinishCallback(onhammered)
	inst.components.workable:SetOnWorkCallback(onhit)

	inst:AddComponent("lootdropper")

    --inst:AddComponent("repairable")
    --inst.components.repairable.repairmaterial = "boat"

    --inst.components.repairable.onrepaired = function(inst, doer, repair_item)
		--if inst.SoundEmitter then
			--inst.SoundEmitter:PlaySound("dontstarve_DLC002/common/boatrepairkit")
		--end
	--end

    inst:ListenForEvent("mounted", onmounted)
    inst:ListenForEvent("dismounted", ondismounted)
 
 	--inst:AddComponent("flotsamspawner")

	return inst
end
	
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

local function rowboatfn(sim)
	local inst = commonfn(sim)

	setupcontainer(inst, {}, "boat_hud_raft", "boat_hud_raft", {}, "boat_inspect_raft", "boat_inspect_raft", {x=0,y=5}, {})

	inst.AnimState:SetBuild("nightmareboat_build")
	inst.AnimState:SetBank("rowboat")
	inst.AnimState:PlayAnimation("run_loop", true)
	
	local minimap = inst.entity:AddMiniMapEntity()
	minimap:SetPriority( 5 )
	minimap:SetIcon("rowboat.png" )

	inst.perishtime = TUNING.ROWBOAT_PERISHTIME
	inst.components.boathealth.maxhealth = 150
	inst.components.boathealth:SetHealth(150, inst.perishtime)
	inst.components.boathealth.leakinghealth = TUNING.ROWBOAT_LEAKING_HEALTH

	inst.landsound = "dontstarve/sanity/creature2/attack"
	inst.sinksound = "dontstarve/sanity/creature2/die"

	inst.components.boathealth.damagesound = "dontstarve/sanity/creature2/attack_grunt"
	
	inst.components.drivable.sanitydrain = -.5
	inst.components.drivable.runspeed = 5
	inst.components.drivable.runanimation = "row_loop"
	inst.components.drivable.prerunanimation = "row_pre"
	inst.components.drivable.postrunanimation = "row_pst"
	inst.components.drivable.overridebuild = "nightmareboat_build"
	inst.components.drivable.flotsambuild = "flotsam_rowboat_build"
	inst.components.drivable.hitfx = "boat_hit_fx_rowboat"
	inst.components.drivable.maprevealbonus = TUNING.MAPREVEAL_ROWBOAT_BONUS+1
	inst.components.drivable.creaksound = "dontstarve_DLC002/common/boat_creaks"

	--inst.components.flotsamspawner.flotsamprefab = "flotsam_rowboat"

	return inst 
end 
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

return Prefab( "common/objects/nightmareboat", rowboatfn, rowboatassets, prefabs),
	MakePlacer( "common/nightmareboat_placer", "rowboat", "nightmareboat_build", "run_loop", false, false, false)
