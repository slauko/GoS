
	local version = 0.01
	local by = "slauko"
	
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
    
    class "Varus"
    if myHero.charName ~="Varus" then return end
-----------------------------------------------------------------Varus THINGS----------------------------------------------------------------------------------------------------------------------
	function Varus:__init()
		Q ={range = myHero:GetSpellData(_Q).range*2-250, delay = myHero:GetSpellData(_Q).delay, speed = myHero:GetSpellData(_Q).speed}
		W ={range =	myHero:GetSpellData(_W).range, delay = myHero:GetSpellData(_W).delay, speed = myHero:GetSpellData(_W).speed}
		E ={range =	myHero:GetSpellData(_E).range, delay = myHero:GetSpellData(_E).delay, speed = myHero:GetSpellData(_E).speed}
		R ={range =	myHero:GetSpellData(_R).range, delay = myHero:GetSpellData(_R).delay, speed = myHero:GetSpellData(_R).speed}
		Q2 ={range = myHero:GetSpellData(_Q).range, delay = myHero:GetSpellData(_Q).delay, speed = myHero:GetSpellData(_Q).speed}
        self:Menu()
        self.chargeQ = false
		Callback.Add("Tick", function() self:Tick() end)
		Callback.Add("Draw", function() self:Draw() end)
	end
--MENU
	function Varus:Menu()
		self.Menu = MenuElement({type = MENU, name = " Varus", id = "Varus"})
			self.Menu:MenuElement({type = MENU, id = "Aimbot", name = "Aimbot"})
			self.Menu.Aimbot:MenuElement({id = "Hold", name = "Hold Enable Key", key = string.byte(" ")})
			self.Menu.Aimbot:MenuElement({id = "Toggle", name = "Toggle Enable Key", key = string.byte("M"), toggle = true})
			self.Menu:MenuElement({type = MENU, name = "Spell Settings", id = "Spell"})
			self.Menu.Spell:MenuElement({id = "Q", name = "Q Key", key = string.byte("Q")})
			self.Menu.Spell:MenuElement({id = "W", name = "W Key", key = string.byte("W")})
			self.Menu.Spell:MenuElement({id = "E", name = "E Key", key = string.byte("E")})
			self.Menu.Spell:MenuElement({id = "R", name = "R Key", key = string.byte("R")})
			self.Menu:MenuElement({type = MENU, name = "Misc Settings", id = "Misc"})
			--self.Menu.Misc:MenuElement({name = "Auto E", id = "autoE", value = true})
			self.Menu:MenuElement({type = MENU, name = "Draw Settings", id = "Draw"})
			self.Menu.Draw:MenuElement({name = "Draw Q", id = "Q", value = true})
			self.Menu.Draw:MenuElement({name = "Draw W", id = "W", value = true})
			self.Menu.Draw:MenuElement({name = "Draw E", id = "E", value = true})
	end
--TICK
	function Varus:Tick()
    qBuff = GetBuffData(myHero,"VarusQLaunch")
		if not myHero.dead  then
		    if (self.Menu.Aimbot.Hold:Value() or self.Menu.Aimbot.Toggle:Value()) then
				self:QAimbot()
				self:WAimbot()
				self:EAimbot()
				self:RAimbot()
			else 
				self:NormalCast() 
			end
			self:Draw()
            self:castingQ()
		end
	end
--Misc
	function Varus:QAimbot()
	local target = _G.SDK.TargetSelector:GetTarget(Q.range+100)
	if target==nil then  
		if self.Menu.Spell.Q:Value() then
		    Control.KeyDown(HK_Q)
		end
        if not self.Menu.Spell.Q:Value() then
		    Control.KeyUp(HK_Q)
		end
	return end
	if target~=nil and target.dead then return end
	local Pred = GetPred(target,math.huge,Game.Latency()/1000)
	   	if IsReady(_Q) and self.Menu.Spell.Q:Value() then
           Control.KeyDown(HK_Q)
        end
        if GetDistance(myHero.pos,Pred) < Q2.range+100 then 
            if not self.Menu.Spell.Q:Value() and qBuff.count > 0 then
                if not Pred:ToScreen().onScreen then
				    pos = myHero.pos + Vector(myHero.pos,Pred):Normalized() * math.random(530,760)
				    Control.CastSpell(HK_Q, pos)
                else
                   Control.CastSpell(HK_Q, Pred)
                end
            end
        end
	end

	function Varus:WAimbot()
	end

	function Varus:EAimbot()
		local target = _G.SDK.TargetSelector:GetTarget(E.range+100)
	    if target==nil then  
		    if self.Menu.Spell.E:Value() then
		    Control.CastSpell(HK_E, mousePos)
		end
	return end
	if target~=nil and target.dead then return end
	local Pred = GetPred(target,math.huge,Game.Latency()/1000)
	   	if GetDistance(myHero.pos,Pred) < E.range+100 and IsReady(_E) and self.Menu.Spell.E:Value() then
            if not Pred:ToScreen().onScreen then
                return end
            if Pred:ToScreen().onScreen then
                Control.CastSpell(HK_E, Pred)
            end
        end
	end

	function Varus:RAimbot()
	local target = _G.SDK.TargetSelector:GetTarget(R.range+100)
	if target==nil then  
		if self.Menu.Spell.R:Value() then
		Control.CastSpell(HK_R, mousePos)
		end
	return end
	if target~=nil and target.dead then return end
	local Pred = GetPred(target,math.huge,Game.Latency()/1000)
		if GetDistance(myHero.pos,Pred) < R.range+100 and IsReady(_R) and self.Menu.Spell.R:Value() then
            if not Pred:ToScreen().onScreen then
				pos = myHero.pos + Vector(myHero.pos,Pred):Normalized() * math.random(530,760)
				Control.CastSpell(HK_R, pos)
            else
                Control.CastSpell(HK_R, Pred)
            end
     	end
	end

	function Varus:NormalCast()
		if self.Menu.Spell.Q:Value() and IsReady(_Q) then
			Control.KeyDown(HK_Q)
		end
        if not self.Menu.Spell.Q:Value() then
            Control.KeyUp(HK_Q)
		end
		if self.Menu.Spell.W:Value() and IsReady(_W) then
			Control.KeyDown(HK_W)
			Control.KeyUp(HK_W)
		end
		if self.Menu.Spell.E:Value() and IsReady(_E) then
			Control.KeyDown(HK_E)
			Control.KeyUp(HK_E)
		end
		if self.Menu.Spell.R:Value() and IsReady(_R) then
			Control.KeyDown(HK_R)
			Control.KeyUp(HK_R)
		end
	end

function Varus:castingQ()
	if self.chargeQ == true then
		Q2.range = 975 + 400*(GetTickCount()-self.qTick)/1000
		if Q2.range >1600 then Q2.range =1600 end
	end
	if self.chargeQ == false and qBuff.count > 0 then
		self.qTick = GetTickCount()
		self.chargeQ = true
	end
	if self.chargeQ == true and qBuff.count == 0 then
		self.chargeQ = false
		Q2.range = 975
    end
end
	
	
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	
--DRAWINGS
	function Varus:Draw()
		local textPos = myHero.pos:To2D()
		if myHero.dead then return end
		if self.Menu.Draw.Q:Value() then
			Draw.Circle(myHero.pos, Q.range, Draw.Color(255,0,0,255))
		end
		if self.Menu.Draw.W:Value() then
			Draw.Circle(myHero.pos, W.range, Draw.Color(255,255,255,255))
		end
		if self.Menu.Draw.E:Value() then
			Draw.Circle(myHero.pos, E.range, Draw.Color(255,255,255,255))
		end
		if (self.Menu.Aimbot.Hold:Value() or self.Menu.Aimbot.Toggle:Value()) then
	   		Draw.Text("Aimbot ON", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 000, 255, 000)) 		
		end
		if not (self.Menu.Aimbot.Hold:Value() or self.Menu.Aimbot.Toggle:Value()) then 
			Draw.Text("Aimbot OFF", 20, textPos.x - 80, textPos.y + 40, Draw.Color(255, 255, 000, 000)) 
		end 
	end

function OnLoad() 
	Varus() 
end
