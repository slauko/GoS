if myHero.charName ~="Graves" then return end
	
function IsReady(slot)
	if Game.CanUseSpell(slot) == 0 then
		return true
	end
		return false
	end

local function GetDistance(p1,p2)
return  math.sqrt(math.pow((p2.x - p1.x),2) + math.pow((p2.y - p1.y),2) + math.pow((p2.z - p1.z),2))
end

local function GetDistance2D(p1,p2)
return  math.sqrt(math.pow((p2.x - p1.x),2) + math.pow((p2.y - p1.y),2))
end

local _AllyHeroes
function GetAllyHeroes()
  if _AllyHeroes then return _AllyHeroes end
  _AllyHeroes = {}
  for i = 1, Game.HeroCount() do
    local unit = Game.Hero(i)
    if unit.isAlly then
      table.insert(_AllyHeroes, unit)
    end
  end
  return _AllyHeroes
end

local _EnemyHeroes
function GetEnemyHeroes()
  if _EnemyHeroes then return _EnemyHeroes end
  for i = 1, Game.HeroCount() do
    local unit = Game.Hero(i)
    if unit.isEnemy then
	  if _EnemyHeroes == nil then _EnemyHeroes = {} end
      table.insert(_EnemyHeroes, unit)
    end
  end
  return {}
end

function IsImmobileTarget(unit)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff and (buff.type == 5 or buff.type == 11 or buff.type == 29 or buff.type == 24 or buff.name == "recall") and buff.count > 0 then
			return true
		end
	end
	return false	
end

local _OnVision = {}
function OnVision(unit)
	if _OnVision[unit.networkID] == nil then _OnVision[unit.networkID] = {state = unit.visible , tick = GetTickCount(), pos = unit.pos} end
	if _OnVision[unit.networkID].state == true and not unit.visible then _OnVision[unit.networkID].state = false _OnVision[unit.networkID].tick = GetTickCount() end
	if _OnVision[unit.networkID].state == false and unit.visible then _OnVision[unit.networkID].state = true _OnVision[unit.networkID].tick = GetTickCount() end
	return _OnVision[unit.networkID]
end
Callback.Add("Tick", function() OnVisionF() end)
local visionTick = GetTickCount()
function OnVisionF()
	if GetTickCount() - visionTick > 100 then
		for i,v in pairs(GetEnemyHeroes()) do
			OnVision(v)
		end
	end
end

local _OnWaypoint = {}
function OnWaypoint(unit)
	if _OnWaypoint[unit.networkID] == nil then _OnWaypoint[unit.networkID] = {pos = unit.posTo , speed = unit.ms, time = Game.Timer()} end
	if _OnWaypoint[unit.networkID].pos ~= unit.posTo then 
		-- print("OnWayPoint:"..unit.charName.." | "..math.floor(Game.Timer()))
		_OnWaypoint[unit.networkID] = {startPos = unit.pos, pos = unit.posTo , speed = unit.ms, time = Game.Timer()}
			DelayAction(function()
				local time = (Game.Timer() - _OnWaypoint[unit.networkID].time)
				local speed = GetDistance2D(_OnWaypoint[unit.networkID].startPos,unit.pos)/(Game.Timer() - _OnWaypoint[unit.networkID].time)
				if speed > 1250 and time > 0 and unit.posTo == _OnWaypoint[unit.networkID].pos and GetDistance(unit.pos,_OnWaypoint[unit.networkID].pos) > 200 then
					_OnWaypoint[unit.networkID].speed = GetDistance2D(_OnWaypoint[unit.networkID].startPos,unit.pos)/(Game.Timer() - _OnWaypoint[unit.networkID].time)
					-- print("OnDash: "..unit.charName)
				end
			end,0.05)
	end
	return _OnWaypoint[unit.networkID]
end

local function GetPred(unit,speed,delay)
	local speed = speed or math.huge
	local delay = delay or 0.25
	local unitSpeed = unit.ms
	if OnWaypoint(unit).speed > unitSpeed then unitSpeed = OnWaypoint(unit).speed end
	if OnVision(unit).state == false then
		local unitPos = unit.pos + Vector(unit.pos,unit.posTo):Normalized() * ((GetTickCount() - OnVision(unit).tick)/1000 * unitSpeed)
		local predPos = unitPos + Vector(unit.pos,unit.posTo):Normalized() * (unitSpeed * (delay + (GetDistance(myHero.pos,unitPos)/speed)))
		if GetDistance(unit.pos,predPos) > GetDistance(unit.pos,unit.posTo) then predPos = unit.posTo end
		return predPos
	else
		if unitSpeed > unit.ms then
			local predPos = unit.pos + Vector(OnWaypoint(unit).startPos,unit.posTo):Normalized() * (unitSpeed * (delay + (GetDistance(myHero.pos,unit.pos)/speed)))
			if GetDistance(unit.pos,predPos) > GetDistance(unit.pos,unit.posTo) then predPos = unit.posTo end
			return predPos
		elseif IsImmobileTarget(unit) then
			return unit.pos
		else
			return unit:GetPrediction(speed,delay)
		end
	end
end

local function CanUseSpell(spell)
	return myHero:GetSpellData(spell).currentCd == 0 and myHero:GetSpellData(spell).level > 0 and myHero:GetSpellData(spell).mana <= myHero.mana
end

function GetPercentHP(unit)
  if type(unit) ~= "userdata" then error("{GetPercentHP}: bad argument #1 (userdata expected, got "..type(unit)..")") end
  return 100*unit.health/unit.maxHealth
end

function GetPercentMP(unit)
  if type(unit) ~= "userdata" then error("{GetPercentMP}: bad argument #1 (userdata expected, got "..type(unit)..")") end
  return 100*unit.mana/unit.maxMana
end

local function GetBuffs(unit)
  local t = {}
  for i = 0, unit.buffCount do
    local buff = unit:GetBuff(i)
    if buff.count > 0 then
      table.insert(t, buff)
    end
  end
  return t
end

function HasBuff(unit, buffname)
  if type(unit) ~= "userdata" then error("{HasBuff}: bad argument #1 (userdata expected, got "..type(unit)..")") end
  if type(buffname) ~= "string" then error("{HasBuff}: bad argument #2 (string expected, got "..type(buffname)..")") end
  for i, buff in pairs(GetBuffs(unit)) do
    if buff.name == buffname then 
      return true
    end
  end
  return false
end

function GetItemSlot(unit, id)
  for i = ITEM_1, ITEM_7 do
    if unit:GetItemData(i).itemID == id then
      return i
    end
  end
  return 0 -- 
end

function GetBuffData(unit, buffname)
  for i = 0, unit.buffCount do
    local buff = unit:GetBuff(i)
    if buff.name == buffname and buff.count > 0 then 
      return buff
    end
  end
  return {type = 0, name = "", startTime = 0, expireTime = 0, duration = 0, stacks = 0, count = 0}--
end

function IsImmune(unit)
  if type(unit) ~= "userdata" then error("{IsImmune}: bad argument #1 (userdata expected, got "..type(unit)..")") end
  for i, buff in pairs(GetBuffs(unit)) do
    if (buff.name == "KindredRNoDeathBuff" or buff.name == "UndyingRage") and GetPercentHP(unit) <= 10 then
      return true
    end
    if buff.name == "VladimirSanguinePool" or buff.name == "JudicatorIntervention" then 
      return true
    end
  end
  return false
end 

function IsValidTarget(unit, range, checkTeam, from)
  local range = range == nil and math.huge or range
  if type(range) ~= "number" then error("{IsValidTarget}: bad argument #2 (number expected, got "..type(range)..")") end
  if type(checkTeam) ~= "nil" and type(checkTeam) ~= "boolean" then error("{IsValidTarget}: bad argument #3 (boolean or nil expected, got "..type(checkTeam)..")") end
  if type(from) ~= "nil" and type(from) ~= "userdata" then error("{IsValidTarget}: bad argument #4 (vector or nil expected, got "..type(from)..")") end
  if unit == nil or not unit.valid or not unit.visible or unit.dead or not unit.isTargetable or IsImmune(unit) or (checkTeam and unit.isAlly) then 
    return false 
  end 
  return unit.pos:DistanceTo(from.pos and from.pos or myHero.pos) < range 
end

function CountAlliesInRange(point, range)
  if type(point) ~= "userdata" then error("{CountAlliesInRange}: bad argument #1 (vector expected, got "..type(point)..")") end
  local range = range == nil and math.huge or range 
  if type(range) ~= "number" then error("{CountAlliesInRange}: bad argument #2 (number expected, got "..type(range)..")") end
  local n = 0
  for i = 1, Game.HeroCount() do
    local unit = Game.Hero(i)
    if unit.isAlly and not unit.isMe and IsValidTarget(unit, range, false, point) then
      n = n + 1
    end
  end
  return n
end

local function CountEnemiesInRange(point, range)
  if type(point) ~= "userdata" then error("{CountEnemiesInRange}: bad argument #1 (vector expected, got "..type(point)..")") end
  local range = range == nil and math.huge or range 
  if type(range) ~= "number" then error("{CountEnemiesInRange}: bad argument #2 (number expected, got "..type(range)..")") end
  local n = 0
  for i = 1, Game.HeroCount() do
    local unit = Game.Hero(i)
    if IsValidTarget(unit, range, true, point) then
      n = n + 1
    end
  end
  return n
end

local DamageReductionTable = {
  ["Braum"] = {buff = "BraumShieldRaise", amount = function(target) return 1 - ({0.3, 0.325, 0.35, 0.375, 0.4})[target:GetSpellData(_E).level] end},
  ["Urgot"] = {buff = "urgotswapdef", amount = function(target) return 1 - ({0.3, 0.4, 0.5})[target:GetSpellData(_R).level] end},
  ["Alistar"] = {buff = "Ferocious Howl", amount = function(target) return ({0.5, 0.4, 0.3})[target:GetSpellData(_R).level] end},
  -- ["Amumu"] = {buff = "Tantrum", amount = function(target) return ({2, 4, 6, 8, 10})[target:GetSpellData(_E).level] end, damageType = 1},
  ["Galio"] = {buff = "GalioIdolOfDurand", amount = function(target) return 0.5 end},
  ["Garen"] = {buff = "GarenW", amount = function(target) return 0.7 end},
  ["Gragas"] = {buff = "GragasWSelf", amount = function(target) return ({0.1, 0.12, 0.14, 0.16, 0.18})[target:GetSpellData(_W).level] end},
  ["Annie"] = {buff = "MoltenShield", amount = function(target) return 1 - ({0.16,0.22,0.28,0.34,0.4})[target:GetSpellData(_E).level] end},
  ["Malzahar"] = {buff = "malzaharpassiveshield", amount = function(target) return 0.1 end}
}

function GotBuff(unit, buffname)
  for i = 0, unit.buffCount do
    local buff = unit:GetBuff(i)
    if buff.name == buffname and buff.count > 0 then 
      return buff.count
    end
  end
  return 0
end

function GetBuffData(unit, buffname)
  for i = 0, unit.buffCount do
    local buff = unit:GetBuff(i)
    if buff.name == buffname and buff.count > 0 then 
      return buff
    end
  end
  return {type = 0, name = "", startTime = 0, expireTime = 0, duration = 0, stacks = 0, count = 0}
end

function CalcPhysicalDamage(source, target, amount)
  local ArmorPenPercent = source.armorPenPercent
  local ArmorPenFlat = (0.4 + target.levelData.lvl / 30) * source.armorPen
  local BonusArmorPen = source.bonusArmorPenPercent

  if source.type == Obj_AI_Minion then
    ArmorPenPercent = 1
    ArmorPenFlat = 0
    BonusArmorPen = 1
  elseif source.type == Obj_AI_Turret then
    ArmorPenFlat = 0
    BonusArmorPen = 1
    if source.charName:find("3") or source.charName:find("4") then
      ArmorPenPercent = 0.25
    else
      ArmorPenPercent = 0.7
    end
  end

  if source.type == Obj_AI_Turret then
    if target.type == Obj_AI_Minion then
      amount = amount * 1.25
      if string.ends(target.charName, "MinionSiege") then
        amount = amount * 0.7
      end
      return amount
    end
  end

  local armor = target.armor
  local bonusArmor = target.bonusArmor
  local value = 100 / (100 + (armor * ArmorPenPercent) - (bonusArmor * (1 - BonusArmorPen)) - ArmorPenFlat)

  if armor < 0 then
    value = 2 - 100 / (100 - armor)
  elseif (armor * ArmorPenPercent) - (bonusArmor * (1 - BonusArmorPen)) - ArmorPenFlat < 0 then
    value = 1
  end
  return math.max(0, math.floor(DamageReductionMod(source, target, PassivePercentMod(source, target, value) * amount, 1)))
end

function CalcMagicalDamage(source, target, amount)
  local mr = target.magicResist
  local value = 100 / (100 + (mr * source.magicPenPercent) - source.magicPen)

  if mr < 0 then
    value = 2 - 100 / (100 - mr)
  elseif (mr * source.magicPenPercent) - source.magicPen < 0 then
    value = 1
  end
  return math.max(0, math.floor(DamageReductionMod(source, target, PassivePercentMod(source, target, value) * amount, 2)))
end

function DamageReductionMod(source,target,amount,DamageType)
  if source.type == Obj_AI_Hero then
    if GotBuff(source, "Exhaust") > 0 then
      amount = amount * 0.6
    end
  end

  if target.type == Obj_AI_Hero then

    for i = 0, target.buffCount do
      if target:GetBuff(i).count > 0 then
        local buff = target:GetBuff(i)
        if buff.name == "MasteryWardenOfTheDawn" then
          amount = amount * (1 - (0.06 * buff.count))
        end
    
        if DamageReductionTable[target.charName] then
          if buff.name == DamageReductionTable[target.charName].buff and (not DamageReductionTable[target.charName].damagetype or DamageReductionTable[target.charName].damagetype == DamageType) then
            amount = amount * DamageReductionTable[target.charName].amount(target)
          end
        end

        if target.charName == "Maokai" and source.type ~= Obj_AI_Turret then
          if buff.name == "MaokaiDrainDefense" then
            amount = amount * 0.8
          end
        end

        if target.charName == "MasterYi" then
          if buff.name == "Meditate" then
            amount = amount - amount * ({0.5, 0.55, 0.6, 0.65, 0.7})[target:GetSpellData(_W).level] / (source.type == Obj_AI_Turret and 2 or 1)
          end
        end
      end
    end

    if GetItemSlot(target, 1054) > 0 then
      amount = amount - 8
    end

    if target.charName == "Kassadin" and DamageType == 2 then
      amount = amount * 0.85
    end
  end

  return amount
end

function PassivePercentMod(source, target, amount, damageType)
  local SiegeMinionList = {"Red_Minion_MechCannon", "Blue_Minion_MechCannon"}
  local NormalMinionList = {"Red_Minion_Wizard", "Blue_Minion_Wizard", "Red_Minion_Basic", "Blue_Minion_Basic"}

  if source.type == Obj_AI_Turret then
    if table.contains(SiegeMinionList, target.charName) then
      amount = amount * 0.7
    elseif table.contains(NormalMinionList, target.charName) then
      amount = amount * 1.14285714285714
    end
  end
  if source.type == Obj_AI_Hero then 
    if target.type == Obj_AI_Hero then
      if (GetItemSlot(source, 3036) > 0 or GetItemSlot(source, 3034) > 0) and source.maxHealth < target.maxHealth and damageType == 1 then
        amount = amount * (1 + math.min(target.maxHealth - source.maxHealth, 500) / 50 * (GetItemSlot(source, 3036) > 0 and 0.015 or 0.01))
      end
    end
  end
  return amount
end

local isCasting = 0 
	function AimbotCast(spell, pos, delay) --Weedle with some adds
	local Cursor = mousePos
    	if pos == nil or isCasting == 1 then return end
    		isCasting = 1
    	    Control.SetCursorPos(pos)
    	    Control.KeyDown(spell)
			DelayAction(function()
			Control.KeyUp(spell)
    	    Control.SetCursorPos(Cursor)
    	    DelayAction(function()
            isCasting = 0
   		    end, 0.002)
        	end, (delay + Game.Latency()) / 1000)
	end 

----------------------------------------------------------------------------------------------------------	
  class "Graves"
	
	function Graves:__init()
		Q = {range =  myHero:GetSpellData(_Q).range, delay = myHero:GetSpellData(_Q).delay, speed = myHero:GetSpellData(_Q).speed}
		W = {range =	myHero:GetSpellData(_W).range, delay = myHero:GetSpellData(_W).delay, speed = myHero:GetSpellData(_W).speed}
		E = {range =	myHero:GetSpellData(_E).range, delay = myHero:GetSpellData(_E).delay, speed = myHero:GetSpellData(_E).speed}
		R = {range =	myHero:GetSpellData(_R).range, delay = myHero:GetSpellData(_R).delay, speed = myHero:GetSpellData(_R).speed}
		
    Callback.Add("Tick", function() self:Tick() end)
		Callback.Add("Draw", function() self:Draw() end)
    
    self:Menu()

    
	end

	function Graves:Menu()
		self.Menu = MenuElement({type = MENU, name = " Graves", id = "Graves"})
		  self.Menu:MenuElement({type = MENU, name = "Combo Settings", id = "Combo"})
		  self.Menu.Combo:MenuElement({name = "Use Q", id = "Q", value = true})
	  	self.Menu.Combo:MenuElement({name = "Use W", id = "W", value = true})
	  	self.Menu.Combo:MenuElement({name = "Use E", id = "E", value = true})
  		self.Menu.Combo:MenuElement({name = "Use R", id = "R", value = true})

	  	self.Menu:MenuElement({type = MENU, name = "Harass Settings", id = "Harass"})
  		self.Menu.Harass:MenuElement({name = "Use Q", id = "Q", value = true})
	  	self.Menu.Harass:MenuElement({name = "Use W", id = "W", value = true})

	  	self.Menu:MenuElement({type = MENU, name = "Laneclear/Jungle Settings", id = "Laneclear"})
	  	self.Menu.Laneclear:MenuElement({name = "Use Q", id = "Q", value = true})
  		self.Menu.Laneclear:MenuElement({name = "Use E", id = "E", value = true})

  		self.Menu:MenuElement({type = MENU, name = "Lasthit Settings", id = "Lasthit"})
  		self.Menu.Lasthit:MenuElement({name = "Use Q", id = "Q", value = true})

      self.Menu:MenuElement({type = MENU, name = "Draw Settings", id = "Draw"})
  		self.Menu.Draw:MenuElement({name = "Draw Q", id = "Q", value = true})
	  	self.Menu.Draw:MenuElement({name = "Draw W", id = "W", value = true})
	  	self.Menu.Draw:MenuElement({name = "Draw E", id = "E", value = true})
	  	self.Menu.Draw:MenuElement({name = "Draw R", id = "R", value = true})
	end

	function Graves:Tick()
  ultdmg = 100+150*myHero:GetSpellData(_R).level+(1.5*myHero.bonusDamage) 
    	if not myHero.dead  then
        if EOW:Mode() == 1 then --Combo
			    self:Combo()
		  	end
			
		  	if EOW:Mode() == 2 then --Harass
		  	  self:Harass()
		  	end

		  	if EOW:Mode() == 4 then --Laneclear
	  		  self:Laneclear()
		  	end

	  		if EOW.Mode()== 3 then --Lasthit
	  		  self:Lasthit()
	  		end 
             
    	end
	end

  function Graves:Combo()
		Qtarget = EOW:GetTarget(Q.range) 
		if Qtarget ~= nil and myHero.pos:DistanceTo(Qtarget.pos) < Q.range-100 and self.Menu.Combo.Q:Value() and IsReady(_Q) then
			predPos = GetPred(Qtarget,Q.speed,Q.delay)
    	AimbotCast(HK_Q, predPos, 100)
    end	
		
		Wtarget = EOW:GetTarget(W.range)
    if Wtarget ~= nil and myHero.pos:DistanceTo(Wtarget.pos) < W.range-100 and self.Menu.Combo.W:Value() and IsReady(_W) then
			predPos = GetPred(Wtarget,W.speed,W.delay)
			AimbotCast(HK_W, predPos, 100)
		end	
		
		Etarget = EOW:GetTarget(myHero.range)
		if Etarget ~=nil and myHero.pos:DistanceTo(Etarget.pos) < E.range and self.Menu.Combo.E:Value() and IsReady(_E) then
			if EOW:CanAttack() == false	then	--AA reset
				AimbotCast(HK_E, mousePos, 100)
			end
		end	
		
		Rtarget = EOW:GetTarget(R.range)
		if Rtarget ~= nil and myHero.pos:DistanceTo(Rtarget.pos) < R.range and self.Menu.Combo.R:Value() and IsReady(_R) then 
      if Rtarget.health-CalcPhysicalDamage(myHero, Rtarget, ultdmg) < 0 then
			  predPos = GetPred(Rtarget,R.speed,R.delay)
			  AimbotCast(HK_R, predPos, 100)
      end
		end 
	end

	function Graves:Harass()
		Qtarget = EOW:GetTarget(Q.range)
		if Qtarget ~=nil and myHero.pos:DistanceTo(Qtarget.pos) < Q.range and self.Menu.Combo.Q:Value() and IsReady(_Q) then
			predPos = GetPred(Qtarget,Q.speed,Q.delay)
			AimbotCast(HK_Q, predPos, 100)
		end	
		
		Wtarget = EOW:GetTarget(W.range)
		if Wtarget ~= nil and myHero.pos:DistanceTo(Wtarget.pos) < W.range and self.Menu.Combo.W:Value() and IsReady(_W)then
			predPos = GetPred(Wtarget,W.speed,W.delay)
			AimbotCast(HK_W, predPos, 100)
		end
			
	end

	function Graves:Laneclear()
		for i = 1, Game.MinionCount() do
			local Minion = Game.Minion(i)
      if Minion.team ~= 100 and not Minion.dead then
			  if myHero.pos:DistanceTo(Minion.pos) < Q.range and self.Menu.Laneclear.Q:Value() and IsReady(_Q) then
          AimbotCast(HK_Q,Minion.pos, 100)
        end
			end
			  if EOW:CanAttack() == false and self.Menu.Laneclear.E:Value() and IsReady(_E) then		--AA reset
			  	AimbotCast(HK_E, mousePos, 100)
			  end	
      
		end
	end

	function Graves:Lasthit()
	end

	function Graves:Draw()
		if myHero.dead then return end
		if self.Menu.Draw.R:Value() then
			Draw.Circle(myHero.pos, R.range, Draw.Color(255,255,255,255))
		end
		if self.Menu.Draw.Q:Value() then
			Draw.Circle(myHero.pos, Q.range, Draw.Color(255,255,255,255))
		end
		if self.Menu.Draw.W:Value() then
			Draw.Circle(myHero.pos, W.range, Draw.Color(255,255,255,255))
		end
		if self.Menu.Draw.E:Value() then
			Draw.Circle(myHero.pos, E.range, Draw.Color(255,255,255,255))
		end
	end

function OnLoad() Graves() end