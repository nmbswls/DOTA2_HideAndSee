
if CTestGameMode == nil then
	--CTestGameMode = class({});
	_G.CTestGameMode = class({});
end

m_PlayerIds = {};



require ("GameEventListener")
require ("funcs")
require ("utility_functions")
require ("settings")
require ("timers")
require ("util")
require ("notifications")

--LinkLuaModifier("modifier_friend_vision", "addon_game_mode", LUA_MODIFIER_MOTION_NONE)

-- Create the game mode when we activate
function Activate()
	GameRules.CTestGameMode = CTestGameMode()
	GameRules.CTestGameMode:InitGameMode()
end


--D:\steam\steamapps\common\dota 2 beta\content\dota\particles\addons_gameplay\pit_lava_blast.vpcf
function Precache( context )
	--[[
		Precache things we know we'll use.  Possible file types include (but not limited to):
			PrecacheResource( "model", "*.vmdl", context )
			PrecacheResource( "soundfile", "*.vsndevts", context )
			PrecacheResource( "particle", "*.vpcf", context )
			PrecacheResource( "particle_folder", "particles/folder", context )
	]]

	PrecacheResource( "particle", "particles/units/heroes/hero_ogre_magi/ogre_magi_fireblast.vpcf", context )

end

function CTestGameMode:InitGameMode()
	print( "Template addon is loaded." )
	GameRules:GetGameModeEntity():SetThink( "OnThink", self, "GlobalThink", 2 );
	
	GameRules:SetHeroRespawnEnabled(false)
	GameRules:SetUseUniversalShopMode(false)
	GameRules:SetSameHeroSelectionEnabled(true)
	GameRules:SetHeroSelectionTime(0)
  	GameRules:SetStrategyTime(0)
  	GameRules:SetShowcaseTime(0)

  	GameRules:SetPreGameTime(PRE_GAME_TIME)
	GameRules:SetPostGameTime(120)

	GameRules:SetCustomGameSetupRemainingTime(-1)
	GameRules:SetCustomGameSetupTimeout(-1)
	GameRules:EnableCustomGameSetupAutoLaunch(false)
  	GameRules:SetCustomGameSetupAutoLaunchDelay(-1)


  	GameRules:SetTreeRegrowTime(0)
  	GameRules:SetUseCustomHeroXPValues(false)
  	GameRules:SetGoldPerTick(0)
  	GameRules:SetGoldTickTime(0)
  	GameRules:SetRuneSpawnTime(0)
  	GameRules:SetUseBaseGoldBountyOnHeroes(false)
  	GameRules:SetFirstBloodActive(false)
  	GameRules:SetHideKillMessageHeaders(true)

	mode = GameRules:GetGameModeEntity();
	mode:SetRecommendedItemsDisabled(true)
  	mode:SetBuybackEnabled(false)
  	mode:SetTopBarTeamValuesVisible(false)
  	mode:SetCustomHeroMaxLevel(1)
  	mode:SetAnnouncerDisabled(false)
  	mode:SetWeatherEffectsDisabled(true)

  	GameRules:GetGameModeEntity():SetItemAddedToInventoryFilter(function(ctx, event)
      local unit = EntIndexToHScript(event.inventory_parent_entindex_const)
      local item = EntIndexToHScript(event.item_entindex_const)

      if unit:IsHero() and unit:GetNumItemsInInventory() >= 6 then
          CreateItemOnPositionSync(unit:GetAbsOrigin(), item)
          return false
      end
      return not (item:GetAbilityName() == "item_tpscroll" and item:GetPurchaser() == nil)
    end, self);

  	self:_RegisterCustomGameEventListeners();

  	CustomGameEventManager:RegisterListener("check_selected_unit", function(_, keys)
        self:CheckSelectedUnit(keys)
    end)

    CustomGameEventManager:RegisterListener("check_zhenying", function(_, keys)
        self:CheckZhenying(keys)
    end)

  	ListenToGameEvent('npc_spawned', Dynamic_Wrap(CTestGameMode, 'OnNPCSpawned'), self)
	ListenToGameEvent('entity_killed', Dynamic_Wrap(CTestGameMode, 'OnEntityKilled'), self)
	ListenToGameEvent( "game_rules_state_change", Dynamic_Wrap( CTestGameMode, 'OnGameRulesStateChange' ), self );

	self.AllObjs = {};
	
	
	self:CollectObjInfo();
	
end

function CTestGameMode:CheckZhenying(keys)
	local player = PlayerResource:GetPlayer(keys.PlayerID);
	local ret = {};
	if PlayerResource:GetCustomTeamAssignment(keys.PlayerID) == DOTA_TEAM_CUSTOM_2 then
		ret.isHider = false;
	else
		ret.isHider = true;
		local hero = player:GetAssignedHero();
		local unit = hero.unit;
		ret.targetEntIdx = unit:GetEntityIndex();
		ret.heroEntIdx = hero:GetEntityIndex();
	end
	CustomGameEventManager:Send_ServerToPlayer(player, 'set_zhenying', ret);
end

function CTestGameMode:CheckSelectedUnit(keys)
	--print("change select");
	local player = PlayerResource:GetPlayer(keys.PlayerID);
	local team = PlayerResource:GetCustomTeamAssignment(keys.PlayerID)
	if team == DOTA_TEAM_CUSTOM_2 then
		--print("bad guys")
		return;
	end
	--print("good guys");



	local hero = player:GetAssignedHero();
	local unit = hero.unit;
	local hasSelectedHero = false;
	for _,eid in pairs(keys.entity) do
		if eid == hero:GetEntityIndex() then
			hasSelectedHero = true;
			break;
		end
	end
	if not hasSelectedHero then
		return;
	end

	if unit == nil then
		return;
	end
	if not unit:IsAlive() then
		return;
	end
	local eid = unit:GetEntityIndex();
	--print(eid);
	CustomGameEventManager:Send_ServerToPlayer(player, 'change_select', {entidx = eid} );
end

-- Evaluate the state of the game
function CTestGameMode:OnThink()
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		--print( "Template addon script is running." )
	elseif GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then
		return nil
	end
	return 1
end

function SelectZhenying()
	GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_2, 3);
	GameRules.AliveSearchers = {};
	GameRules.AliveHidders = {};
	GameRules.HidderUnits = {};
	GameRules.playerObjCounter = {};
	

	local allPlayersIDs = {}
	for pID=0, DOTA_MAX_TEAM_PLAYERS do
		if PlayerResource:IsValidPlayerID(pID) then
			table.insert(allPlayersIDs, pID)
			PlayerResource:SetCustomTeamAssignment(pID, DOTA_TEAM_CUSTOM_1)
		end
	end
	local randList = ShuffledList(allPlayersIDs);
	local numPlayers = #allPlayersIDs;

	local numHider = 0;
	local numSearcher = 0;
	if numPlayers == 1 then
		numSearcher = 1;
	elseif numPlayers <= 4 then 
		numSearcher = 1;
	elseif numPlayers <= 9 then
		numSearcher = 2;
	else
		numSearcher = 3;
	end

	--print(#randList);
	for i = 1,numSearcher do 
		local pid = randList[i];
		print("pid:".. pid);
		PlayerResource:SetCustomTeamAssignment(pid , DOTA_TEAM_CUSTOM_2);
		PlayerResource:SetSelectedHero(pid, SERCHER_HERO);
		table.insert(GameRules.AliveSearchers,pid);
	end

	local idx = 1;
	for i = numSearcher+1, numPlayers do
		local pid = randList[i];
		--PlayerResource:SetCustomTeamAssignment(pid , DOTA_TEAM_CUSTOM_2);
		PlayerResource:SetSelectedHero(pid, HIDDER_HERO);
		table.insert(GameRules.AliveHidders,pid);
		local player = PlayerResource:GetPlayer(pid);
		--print(player:GetPlayerID());
		--CreateHeroForPlayer(HIDDER_HERO,player);
		if idx < #PLAYER_COLORS then
			local color = PLAYER_COLORS[idx]
			PlayerResource:SetCustomPlayerColor(pid, color[1], color[2], color[3]);
			idx = idx + 1;
		end
	end
end


function CTestGameMode:CollectObjInfo()
	local objs = Entities:FindAllByClassname("prop_dynamic");
	GameRules.ObjInfoDict = {};
	print("objs num:" .. #objs);
	for _,o in pairs(objs) do
		local tid = o:Attribute_GetIntValue("ObjType",-1);
		
		print("dict info:" .. tid);
		if tid >=0 then
			local info = {};
			
			info.tid = tid;
			info.pos = o:GetAbsOrigin();
			info.faceDir = o:GetForwardVector();
			
			table.insert(GameRules.ObjInfoDict, info);
			o:Destroy();
		end
	end

end

function CTestGameMode:RandomInitMap()
	if not GameRules.ObjInfoDict then
		self:CollectObjInfo();
	end
	--for _,obj in pairs(GameRules.ObjInfoDict) do
		--print(obj.tid .. obj.pos.x .. obj.faceDir.x);
	--end
	

	--local spawners = Entities:FindAllByName("hAs_obj_spawner");
	local spawners = GameRules.ObjInfoDict;
	self.AllObjs = {};
	local collection = {};

	for _,spawner in pairs(spawners) do
		--local tid = spawner:Attribute_GetIntValue("Type",-1);
		local tid = spawner.tid;
		if tid >= 0 then
			if collection[tid] == nil then
				collection[tid] = {};
			end
			table.insert(collection[tid],spawner);
		end
	end
	for tid,list in pairs(collection) do
		--根据tid 决定少几个
		local lessCount = 1;
		if GameRules.playerObjCounter[tid] ~= nil then
			lessCount = lessCount + GameRules.playerObjCounter[tid];
		end
		
		local randList = ShuffledList(list);
		for i = 1, #randList - lessCount do
			local spawnedObj = SpawnHASObj(randList[i]);
			table.insert(self.AllObjs,spawnedObj);
		end
	end
	
end



function CTestGameMode:PreStart()

	
	self:RandomInitMap();

	local gameStartTimer = PRE_GAME_TIME;
	Timers:CreateTimer(function()
		if gameStartTimer > 0 then
			Notifications:ClearBottomFromAll()
			Notifications:BottomToAll({text="Game starts in " .. gameStartTimer, style={color='#E62020'}, duration=1})
			gameStartTimer = gameStartTimer - 1
			return 1
		else
			Notifications:ClearBottomFromAll()
			Notifications:BottomToAll({text="Game started!", style={color='#E62020'}, duration=1})
			GameRules.startTime = GameRules:GetGameTime()

			-- Unstun the elves
			local hidderCount = PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_CUSTOM_1);
			for i=1, hidderCount do
				local pID = PlayerResource:GetNthPlayerIDOnTeam(DOTA_TEAM_CUSTOM_1, i)
				local playerHero = PlayerResource:GetSelectedHeroEntity(pID)
				if playerHero then
					playerHero:RemoveModifierByName("modifier_stunned");
					--playerHero:SetDayTimeVisionRange(1000);
					--playerHero:SetNightTimeVisionRange(800);
					--PlayerResource:SetOverrideSelectionEntity(pID,playerHero.unit);
				end
			end

			local searcherSpawnTimer = SEARCHER_SPAWN_TIME;
			local AliveSearchers = GameRules.AliveSearchers;
			for _,pid in pairs(AliveSearchers) do
				local hero = PlayerResource:GetPlayer(pid):GetAssignedHero();
				--hero:AddNewModifier(nil, nil, "modifier_special_bonus_vision", {duration=searcherSpawnTimer})
				hero:AddNewModifier(nil, nil, "modifier_stunned", {duration=searcherSpawnTimer})
			end

			Timers:CreateTimer(function()
				if searcherSpawnTimer > 0 then
					Notifications:ClearBottomFromAll()
					Notifications:BottomToAll({text="Searchers spawns in " .. searcherSpawnTimer, style={color='#E62020'}, duration=1})
					searcherSpawnTimer = searcherSpawnTimer - 1
					return 1.0
				else
					local searcherCount = PlayerResource:GetPlayerCountForTeam(DOTA_TEAM_CUSTOM_2);
					for i=1, searcherCount do
						local pID = PlayerResource:GetNthPlayerIDOnTeam(DOTA_TEAM_CUSTOM_2, i)
						local playerHero = PlayerResource:GetSelectedHeroEntity(pID)
						if playerHero then
							playerHero:RemoveModifierByName("modifier_stunned")
							playerHero:SetDayTimeVisionRange(1000);
							playerHero:SetNightTimeVisionRange(800);
						end
						GameRules.TurnTImeLeft = BASE_TURN_TIME;
						Timers:CreateTimer(self.TestTick);
						
					end
					
				end
			end)
		end
	end)

end

function CTestGameMode:TestTick()
	print("tick");
	if GameRules.TurnTImeLeft > 0 then
		GameRules.TurnTImeLeft = GameRules.TurnTImeLeft - 1;
		return 1.0;
	else
		print("end tick");
	end
	
end

function CTestGameMode:OnEntityKilled(keys)

	print(keys.entindex_killed .. "," .. keys.entindex_attacker .. "," .. keys.entindex_inflictor);



	local entindex_killed = EntIndexToHScript(keys.entindex_killed)
	local entindex_attacker = EntIndexToHScript(keys.entindex_attacker)
	local entindex_inflictor = EntIndexToHScript(keys.entindex_inflictor)

	if entindex_killed == nil then
		return;
	end

	if entindex_killed:IsHero() then
		if entindex_killed:GetTeam() == DOTA_TEAM_CUSTOM_2 then
			local pid = entindex_killed:GetPlayerOwnerID();
			table.remove(GameRules.AliveSearchers,pid);
			self:CheckGameEnd();
		else
			print("error branch")
		end
		return;
	end


	--print(entindex_attacker:GetName());

	if entindex_killed.hidder_owner == nil then
		entindex_killed:RespawnUnit();
		ApplyDamage({victim = entindex_attacker,
			attacker=entindex_killed,
			damage = 200, 
			damage_type = DAMAGE_TYPE_PURE})

		local paticle = "particles/units/heroes/hero_ogre_magi/ogre_magi_fireblast.vpcf";
		ParticleManager:CreateParticle(paticle, PATTACH_ABSORIGIN, entindex_killed);
		self:CheckGameEnd();
		return;
	else
		print("killed right");
		entindex_killed.hidder_owner.unit = nil;
		local hero = entindex_killed.hidder_owner;
		hero:Kill();
		entindex_killed:Destroy();
		local pid = hero:GetPlayerOwnerID();
		table.remove(GameRules.AliveHidders,pid);
		if entindex_killed:GetTeam() == DOTA_TEAM_CUSTOM_2 then
			local pid = entindex_killed:GetPlayerOwnerID()();
			table.remove(GameRules.AliveSearchers,pid);
		end
		Notifications:BottomToAll({text="dead dead dead", style={color='#E62020'}, duration=1});
		self:CheckGameEnd();
	end

end

function CTestGameMode:CheckGameEnd()

	if #GameRules.AliveHidders == 0 then
		Notifications:BottomToAll({text="game end searchers win ", style={color='#000000'}, duration=3})
		Timers:CreateTimer(5, function()
			self:NextRound();
		end)
	elseif #GameRules.AliveSearchers == 0 then
		Notifications:BottomToAll({text="game end hidders win ", style={color='#000000'}, duration=3})
		Timers:CreateTimer(5, function()
			self:NextRound();
		end)
	end
	--SetOverrideSelectionEntity
	
end


function CTestGameMode:NextRound()
	GameRules.startTime = nil;
	self:DestoryAllHASObjs();

	--重置阵营
	CustomGameEventManager:Send_ServerToAllClients('reset_zhenying', {});

	GameRules:ResetToCustomGameSetup();
end

function CTestGameMode:DestoryAllHASObjs()
	--摧毁之前创造的unit
	for _,obj in pairs(self.AllObjs) do
		if obj then
			obj:Destroy();
		end
	end

	for _,unit in pairs(GameRules.HidderUnits) do
		if unit then
			unit:Destroy();
		end
	end
end

function CTestGameMode:OnNPCSpawned(keys)
  
  local npc = EntIndexToHScript(keys.entindex)

  
  if npc:IsRealHero() and npc.bFirstSpawned == nil then
    npc.bFirstSpawned = true
    CTestGameMode:OnHeroInGame(npc)
  end
end

function CTestGameMode:OnHeroInGame(hero)
	print("OnHeroInGame")
	local team = hero:GetTeamNumber()
	InitializeHero(hero)
	print("team:" .. team);
	if team == DOTA_TEAM_CUSTOM_2 then
		InitializeSearcher(hero);
	else 
		InitializeHidder(hero);
	end
end





function InitializeHero(hero)
	DebugPrint("Initialize hero")
	PlayerResource:SetGold(hero, 0)
	if not GameRules.startTime then
		hero:AddNewModifier(nil, nil, "modifier_stunned", nil)
	end

	hero:ClearInventory()
	-- Learn all abilities (this isn't necessary on creatures)
	for i=0, hero:GetAbilityCount()-1 do
		local ability = hero:GetAbilityByIndex(i)
		if ability then ability:SetLevel(ability:GetMaxLevel()) end
	end
	hero:SetAbilityPoints(0)
end

function UpdateSpells(unit)
	--赋予初始技能
end

function InitializeHidder(hero)
	DebugPrint("Initialize hidder")
	UpdateSpells(hero);

	
	local targetObj = Entities:FindByName(nil,"game_origin");
	--npc_dota_creature_gnoll_assassin
	local pos = targetObj:GetAbsOrigin();

	local tid = RandomInt(1,3);
	local objName = TidToNameDict[tid];
	if GameRules.playerObjCounter[tid] == nil then
		GameRules.playerObjCounter[tid] = 1;
	else
		GameRules.playerObjCounter[tid] = GameRules.playerObjCounter[tid] + 1;
	end

 	local unit = CreateUnitByName(objName,pos,true,nil,nil,DOTA_TEAM_CUSTOM_1);
 	if hero.unit then
 		hero.unit:Kill();
 	end

 	local randAbility = unit:AddAbility("ability_rand_01");
	randAbility:SetLevel(randAbility:GetMaxLevel());

 	--unit:SetModel("maps/backgrounds/models/fairy_showcase_lantern/fairy_showcase_lantern.vmdl")
 	--local unit = CreateUnitByName("npc_dota_creature_gnoll_assassin",pos,true,nil,nil,DOTA_TEAM_CUSTOM_2);
 	hero.unit = unit;
 	unit.hidder_owner = hero;
 	table.insert(GameRules.HidderUnits,unit);
 	
 	local pid = hero:GetPlayerOwnerID();
 	unit:SetControllableByPlayer(pid,true);
 	
 	unit:SetDayTimeVisionRange(1000);
	unit:SetNightTimeVisionRange(800);
	--modifier_provide_vision
	--unit:AddNewModifier(hero, nil, "modifier_friend_vision", {duration=-1})
end

function InitializeSearcher(hero)
	DebugPrint("Initialize searcher");

	
	hero:SetBaseHealthRegen(5);

	--print(hero:GetEntity())

	UpdateSpells(hero);
	

	
end

function CDOTA_BaseNPC:ClearInventory()
	local item_count = self:GetNumItemsInInventory()
	for i=0, item_count do
		local item = self:GetItemInSlot(i)
		self:RemoveItem(item)
	end
end

function CDOTA_PlayerResource:SetGold(hero,gold)
    local playerID = hero:GetPlayerOwnerID()
 --    gold = math.min(gold, 1000000)
 --    GameRules.gold[playerID] = gold
	-- CustomGameEventManager:Send_ServerToTeam(hero:GetTeam(), "player_custom_gold_changed", {
	-- 	playerID = playerID,
	-- 	gold = PlayerResource:GetGold(playerID)
	-- })
	hero:SetGold(1,true);
end

function CTestGameMode:OnGameRulesStateChange()
	local nNewState = GameRules:State_Get();
	if nNewState == DOTA_GAMERULES_STATE_PRE_GAME then
		print("pre game");
		self:PreStart();
		--self:StartNewRound();
	elseif nNewState == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
		print("game setup");
		self:GameSetup();
		
		-- for team = DOTA_TEAM_CUSTOM_1, (DOTA_TEAM_COUNT-1) do
		-- 	GameRules:SetCustomGameTeamMaxPlayers( team, 1 );
		-- end
	end
	
end

function CTestGameMode:GameSetup()
	GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_1, 12 );
	GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_2, 0 );
	GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_GOODGUYS, 0 );
	GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_BADGUYS, 0 );
	Timers:CreateTimer(TEAM_CHOICE_TIME, function()
		--InitMap();
		SelectZhenying()
		GameRules:FinishCustomGameSetup()
	end)
	-- Timers:CreateTimer(TEAM_CHOICE_TIME, function()
	-- 	SelectZhenying();

	-- 	GameRules:FinishCustomGameSetup();
	-- end)
end






function CDOTA_PlayerResource:SetSelectedHero(playerID, heroName)
    local player = PlayerResource:GetPlayer(playerID)
	if player == nil then
        GameRules.disconnectedHeroSelects[playerID] = heroName
        return
	end
    player:SetSelectedHero(heroName)
end


function SpawnHASObj(spawner)
	--local pos = spawner:GetAbsOrigin();
	--local faceDir = spawner:GetForwardVector();
	--local tid = spawner:Attribute_GetIntValue("Type",0);
	
	local pos = spawner.pos;
	local faceDir = spawner.faceDir;
	local tid = spawner.tid;
	
	print("tid:" .. tid);
	if tid > 0 and TidToNameDict[tid] ~= nil then
		local unit = CreateUnitByName(TidToNameDict[tid],pos,false,nil,nil,DOTA_TEAM_CUSTOM_3);
		unit:SetForwardVector(faceDir);
		return unit;
	end

end


TidToNameDict = {
	[1] = "npc_dota_obj_01",
	[2] = "npc_dota_obj_02",
	[3] = "npc_dota_obj_03",
}



