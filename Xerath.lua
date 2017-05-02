if myHero.charName ~="Xerath" then return end
	local version = 0.01
	local by = "slauko"
	class "Xerath"
	require("DamageLib")

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
			local predPos = unitPos + (Vector(unit.pos,unit.posTo):Normalized() * (unitSpeed * (delay + (GetDistance(myHero.pos,unitPos)/speed))))/2 --here
			if GetDistance(unit.pos,predPos) > GetDistance(unit.pos,unit.posTo) then predPos = unit.posTo end
				return predPos
			else
			if unitSpeed > unit.ms then
				local predPos = unit.pos + (Vector(OnWaypoint(unit).startPos,unit.posTo):Normalized() * (unitSpeed * (delay + (GetDistance(myHero.pos,unit.pos)/speed))))/2 --here
				if GetDistance(unit.pos,predPos) > GetDistance(unit.pos,unit.posTo) then predPos = unit.posTo end
					return predPos
			elseif IsImmobileTarget(unit) then
					return unit.pos
			else
				return unit:GetPrediction(speed,delay)
			end
		end
	end
-----------------------------------------------------------------XERATH THINGS----------------------------------------------------------------------------------------------------------------------
	function Xerath:__init()
		Q ={range = myHero:GetSpellData(_Q).range*2, delay = myHero:GetSpellData(_Q).delay, speed = myHero:GetSpellData(_Q).speed}
		W ={range =	myHero:GetSpellData(_W).range, delay = myHero:GetSpellData(_W).delay, speed = myHero:GetSpellData(_W).speed}
		E ={range =	myHero:GetSpellData(_E).range, delay = myHero:GetSpellData(_E).delay, speed = myHero:GetSpellData(_E).speed}
		R ={range =	2000 + 1220*myHero:GetSpellData(_R).level, delay = myHero:GetSpellData(_R).delay, speed = myHero:GetSpellData(_R).speed}
		Q2={range = myHero:GetSpellData(_Q).range}
		self.qTick = GetTickCount()	
		self.chargeQ = false	
		self:Menu()
		Callback.Add("Tick", function() self:Tick() end)
		Callback.Add("Draw", function() self:Draw() end)
	end
--MENU
	function Xerath:Menu()
		self.Menu = MenuElement({type = MENU, name = " Xerath", id = "Xerath"})
			self.Menu:MenuElement({type = MENU, name = "Combo Settings", id = "Combo"})
			self.Menu.Combo:MenuElement({name = "Use Q", id = "Q", value = true})
			self.Menu.Combo:MenuElement({name = "Use W", id = "W", value = true})
			self.Menu.Combo:MenuElement({name = "Use E Aimbot", id = "E", key = string.byte("G")})
			self.Menu.Combo:MenuElement({name = "Use R Aimbot", id = "R", key = string.byte("T")})

			self.Menu:MenuElement({type = MENU, name = "Draw Settings", id = "Draw"})
			self.Menu.Draw:MenuElement({name = "Draw Q", id = "Q", value = true})
			self.Menu.Draw:MenuElement({name = "Draw charging Q", id = "Q2", value = true})
			self.Menu.Draw:MenuElement({name = "Draw W", id = "W", value = true})
			self.Menu.Draw:MenuElement({name = "Draw E", id = "E", value = true})
			self.Menu.Draw:MenuElement({name = "Draw R", id = "R", value = true})
	end
--TICK
	function Xerath:Tick()
	rBuff = GetBuffData(myHero,"XerathLocusOfPower2")
	qBuff = GetBuffData(myHero,"XerathArcanopulseChargeUp")
    --PrintChat("" ,qBuff.count)
		if not myHero.dead  then
		   if _G.SDK.Orbwalker.Modes[_G.SDK.ORBWALKER_MODE_COMBO] then   
        		self:Combo()
	       end        
		   if rBuff.count > 0 then
				self:RCast()
		   end
		   if self.Menu.Combo.E:Value() then
		   		self:ECast()
		   end
		end
		self:castingQ(qBuff)
	end
--COMBO
	function Xerath:Combo()
	local target = _G.SDK.TargetSelector:GetTarget(Q.range)
	if target==nil then return end
	if target~=nil and target.dead then return end
	local qPred = GetPred(target,math.huge,0.35 + Game.Latency()/1000)
	local wPred = GetPred(target,math.huge,0.35 + Game.Latency()/1000)	
		if myHero.pos:DistanceTo(qPred) < Q.range and self.Menu.Combo.Q:Value() and IsReady(_Q) then
			Control.KeyDown(HK_Q)
				if myHero.pos:DistanceTo(qPred) < Q2.range-100 then
					if not qPred:ToScreen().onScreen then
						pos = myHero.pos + Vector(myHero.pos,qPred):Normalized() * math.random(530,760)
						Control.CastSpell(HK_Q, pos)
					else
						Control.CastSpell(HK_Q, qPred)
					end
				end
		end
		if myHero.pos:DistanceTo(wPred) < W.range and self.Menu.Combo.W:Value() and IsReady(_W) and self.chargeQ == false and IsImmobileTarget(target) then
			Control.CastSpell(HK_W,wPred)
			DelayAction(function()end,0.03)
		end
	end
	
	function Xerath:ECast()
	local target = _G.SDK.TargetSelector:GetTarget(E.range)
	if target==nil then return end
	if target~=nil and target.dead then return end
	local ePred = GetPred(target,E.speed,0.35 + Game.Latency()/1000)
		if myHero.pos:DistanceTo(ePred) < E.range and IsReady(_E) then
			if not ePred:ToScreen().onScreen then
						pos = myHero.pos + Vector(myHero.pos,ePred):Normalized() * math.random(530,760)
						AimbotCast(HK_E, pos, 100)	
					else
						AimbotCast(HK_E, ePred, 100)
					end
		end
	end
	
	function Xerath:RCast()
	local target = _G.SDK.TargetSelector.SelectedTarget
	if target==nil then return end
	if target~=nil and target.dead then return end
		if self.Menu.Combo.R:Value() then
			local rPred = GetPred(target,math.huge,0.45)
			if rPred:ToScreen().onScreen then
				AimbotCast(HK_R, rPred, 100)
			end
		end
	end
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	function Xerath:castingQ(qBuff) --Noddy
	if self.chargeQ == true then
		Q2.range = 750 + 500*(GetTickCount()-self.qTick)/1000
		if Q2.range > 1500 then Q2.range = 1500 end
	end
	if self.chargeQ == false and qBuff.count > 0 then
		self.qTick = GetTickCount()
		self.chargeQ = true
	end
	if self.chargeQ == true and qBuff.count == 0 then
		self.chargeQ = false
		Q2.range = 750
		if Control.IsKeyDown(HK_Q) == true then
			Control.KeyUp(HK_Q)
		end
	end
	if Control.IsKeyDown(HK_Q) == true and self.chargeQ == false then
		DelayAction(function()
			if Control.IsKeyDown(HK_Q) == true and self.chargeQ == false then
				Control.KeyUp(HK_Q)
			end
		end,0.3)
	end
	if Control.IsKeyDown(HK_Q) == true and Game.CanUseSpell(_Q) ~= 0 then
		DelayAction(function()
			if Control.IsKeyDown(HK_Q) == true then
				Q2.range = 750
				Control.KeyUp(HK_Q)
			end
		end,0.01)
	end
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

--DRAWINGS
	function Xerath:Draw()
		if myHero.dead then return end
		if self.Menu.Draw.R:Value() and IsReady(_R) then
			Draw.Circle(myHero.pos,2000 + 1220*myHero:GetSpellData(_R).level,1.5,Draw.Color(255,255,255,255))
			Draw.CircleMinimap(myHero.pos,2000 + 1220*myHero:GetSpellData(_R).level,1.5,Draw.Color(255,255,255,255))
		end
		if self.Menu.Draw.Q:Value() then
			Draw.Circle(myHero.pos, Q.range, Draw.Color(255,255,255,255))
		end
		if self.Menu.Draw.Q2:Value() then
			Draw.Circle(myHero.pos, Q2.range, Draw.Color(255,0,0,255))
		end
		if self.Menu.Draw.W:Value() then
			Draw.Circle(myHero.pos, W.range, Draw.Color(255,255,255,255))
		end
		if self.Menu.Draw.E:Value() then
			Draw.Circle(myHero.pos, E.range, Draw.Color(255,255,255,255))
		end
		if self.Menu.Draw.R:Value() and self.Menu.Combo.R:Value() then
			Draw.Text("R on marked Target", 20, mousePos:To2D().x - 80, mousePos:To2D().y + 40, Draw.Color(255, 255, 000, 000))
		end
	end

function OnLoad() 
	Xerath() 
end
