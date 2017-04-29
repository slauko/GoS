local SlaukoChamps = {"Ekko"}
if not table.contains(SlaukoChamps, myHero.charName)  then print("" ..myHero.charName.. " Is Not Supported") return end

local function Ready(spell)
	return myHero:GetSpellData(spell).currentCd == 0 and myHero:GetSpellData(spell).level > 0 and myHero:GetSpellData(spell).mana <= myHero.mana
end

local Slauko = MenuElement({type = MENU, id = "Slauko", name = "SlaukoAim", leftIcon = "http://www.clipartbest.com/cliparts/LiK/kb9/LiKkb9e6T.png"})
Slauko:MenuElement({type = MENU, id = "Spell", name = "Spell Settings"})
	Slauko.Spell:MenuElement({id = "Enabled", name = "Enabled", key = string.byte(" "), toggle = true})
Slauko:MenuElement({type = MENU, id = "Draw", name = "Draw Settings"})
	Slauko.Draw:MenuElement({id = "Enabled", name = "Enable all Drawings", value = true})
	Slauko.Draw:MenuElement({id = "OFFDRAW", name = "Draw text when Off", value = true})
Slauko:MenuElement({type = SPACE, name = "Version 0.1 by Slauko"})		


local _AllyHeroes
local function GetAllyHeroes()
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
local function GetEnemyHeroes()
	if _EnemyHeroes then return _EnemyHeroes end
	_EnemyHeroes = {}
	for i = 1, Game.HeroCount() do
		local unit = Game.Hero(i)
		if unit.isEnemy then
			table.insert(_EnemyHeroes, unit)
		end
	end
	return _EnemyHeroes
end

local function GetPercentHP(unit)
	if type(unit) ~= "userdata" then error("{GetPercentHP}: bad argument #1 (userdata expected, got "..type(unit)..")") end
	return 100*unit.health/unit.maxHealth
end

local function GetPercentMP(unit)
	if type(unit) ~= "userdata" then error("{GetPercentMP}: bad argument #1 (userdata expected, got "..type(unit)..")") end
	return 100*unit.mana/unit.maxMana
end

local function GetBuffData(unit, buffname)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff.name == buffname and buff.count > 0 then 
			return buff
		end
	end
	return {type = 0, name = "", startTime = 0, expireTime = 0, duration = 0, stacks = 0, count = 0}
end

local function IsImmobileTarget(unit)
	for i = 0, unit.buffCount do
		local buff = unit:GetBuff(i)
		if buff and (buff.type == 5 or buff.type == 11 or buff.type == 29 or buff.type == 24 or buff.name == "recall") and buff.count > 0 then
			return true
		end
	end
	return false	
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

local sqrt = math.sqrt 
local function GetDistance(p1,p2)
	return sqrt((p2.x - p1.x)*(p2.x - p1.x) + (p2.y - p1.y)*(p2.y - p1.y) + (p2.z - p1.z)*(p2.z - p1.z))
end

local function GetDistance2D(p1,p2)
	return sqrt((p2.x - p1.x)*(p2.x - p1.x) + (p2.y - p1.y)*(p2.y - p1.y))
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
	if unit == nil then return end
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

local isCasting = 0 
function SlaukoCast(pos, delay) --Weedle copy pasta Keepo
local Cursor = mousePos
    if pos == nil or isCasting == 1 then return end
    isCasting = 1
        Control.SetCursorPos(pos)
        DelayAction(function()
        Control.SetCursorPos(Cursor)
        DelayAction(function()
         isCasting = 0
        end, 0.002)
        end, (delay + Game.Latency()) / 1000)
end 


class "Ekko"

function Ekko:__init()
	print("Slauko | Ekko")
	Callback.Add("Tick", function() self:Tick() end)
	Callback.Add("Draw", function() self:Draw() end)
	self:Menu()
end

function Ekko:Menu()
	Slauko.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
	Slauko.Spell:MenuElement({id = "QR", name = "Q Range", value = 800, min = 0, max = 800, step = 10}) --not Range 1050 because slow down
	Slauko.Spell:MenuElement({id = "W", name = "W Key", key = string.byte("W")})
	Slauko.Spell:MenuElement({id = "WR", name = "W Range", value = 1600, min = 0, max = 1600, step = 10})

	Slauko.Draw:MenuElement({id = "QD", name = "Draw Q range", type = MENU})
    Slauko.Draw.QD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    Slauko.Draw.QD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    Slauko.Draw.QD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
    Slauko.Draw:MenuElement({id = "WD", name = "Draw W range", type = MENU})
    Slauko.Draw.WD:MenuElement({id = "Enabled", name = "Enabled", value = true})       
    Slauko.Draw.WD:MenuElement({id = "Width", name = "Width", value = 1, min = 1, max = 5, step = 1})
    Slauko.Draw.WD:MenuElement({id = "Color", name = "Color", color = Draw.Color(255, 255, 255, 255)})
end

function Ekko:Tick()
	if Slauko.Spell.Enabled:Value() then
		if Slauko.Spell.Q:Value() then
			self:Q()
		end
		if Slauko.Spell.W:Value() then
			self:W()
		end
		--if Slauko.Spell.E:Value() then
		--	self:E()
		--end
	end
end

function Ekko:Q()
local target =  _G.SDK.TargetSelector:GetTarget(800)
if target == nil then return end 	
	local pos = GetPred(target, 800, (0.25 + Game.Latency())/1000)
	SlaukoCast(pos, 100)
end

function Ekko:W()
local target =  _G.SDK.TargetSelector:GetTarget(1600)	
if target == nil then return end 		
	local pos = GetPred(target, 1600, 0.25 + Game.Latency()/1000)
	SlaukoCast(pos, 100)
end

--function Ekko:E()		--maybe something like... if selected target in buffed range while buffed do automatically autoattack
--local target =  _G.SDK.TargetSelector:GetTarget(425)	
--if target == nil then return end 		
	--local pos = GetPred(target, 425, 0.25 + Game.Latency()/1000)
	--SlaukoCast(pos, 100)
--end

function Ekko:Draw()
	if not myHero.dead then
	   	if Slauko.Draw.Enabled:Value() then
	   		local textPos = myHero.pos:To2D()
	   		if Slauko.Spell.Enabled:Value() then
				Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
			end
			if not Slauko.Spell.Enabled:Value() and Slauko.Draw.OFFDRAW:Value() then 
				Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
			end 
			if Slauko.Draw.QD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, Slauko.Spell.QR:Value(), Slauko.Draw.QD.Width:Value(), Slauko.Draw.QD.Color:Value())
	    	end
	    	if Slauko.Draw.WD.Enabled:Value() then
	    	    Draw.Circle(myHero.pos, Slauko.Spell.WR:Value(), Slauko.Draw.WD.Width:Value(), Slauko.Draw.WD.Color:Value())
	    	end
	    end		
	end
end

if _G[myHero.charName]() then print("Welcome back " ..myHero.name..", thank you for using my Ekko") end
