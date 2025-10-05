if( SERVER ) then
	AddCSLuaFile( "shared.lua" )
end

SWEP.Category = "NPC_WEAPONS"
SWEP.Author			= ""

SWEP.Spawnable			= false
SWEP.AdminSpawnable		= false
SWEP.GrenadeTimer       = false
SWEP.ViewModel      = ""
SWEP.WorldModel   = "models/weapons/doi/w_marinebayonet.mdl"
SWEP.RunAwayTimer          = false
SWEP.Primary.Damage		= math.random(25,30)

SWEP.Primary.ClipSize		= -1					-- Size of a clip
SWEP.Primary.DefaultClip	= -1					-- Default number of bullets in a clip
SWEP.Primary.Automatic		= true				-- Automatic/Semi Auto
SWEP.Primary.Ammo			= "none"
SWEP.Secondary.ClipSize		= -1					-- Size of a clip
SWEP.Secondary.DefaultClip	= -1					-- Default number of bullets in a clip
SWEP.Secondary.Automatic	= false				-- Automatic/Semi Auto
SWEP.Secondary.Ammo		= "none"
SWEP.BaseCombineHoldType    = false
SWEP.Slash = 1
SWEP.IsCombine              = false
SWEP.CooldownTimer          = false


function SWEP:Initialize()
if CLIENT then
	
		-- // Create a new table for every weapon instance
		self.VElements = table.FullCopy( self.VElements )
		self.WElements = table.FullCopy( self.WElements )
		self.ViewModelBoneMods = table.FullCopy( self.ViewModelBoneMods )

		self:CreateModels(self.VElements) -- create viewmodels
		self:CreateModels(self.WElements) -- create worldmodels
		
		-- // init view model bone build function
		if IsValid(self.Owner) and self.Owner:IsPlayer() then
		if self.Owner:Alive() then
			local vm = self.Owner:GetViewModel()
			if IsValid(vm) then
				self:ResetBonePositions(vm)
				-- // Init viewmodel visibility
				if (self.ShowViewModel == nil or self.ShowViewModel) then
					vm:SetColor(Color(255,255,255,255))
				else
					-- // however for some reason the view model resets to render mode 0 every frame so we just apply a debug material to prevent it from drawing
					vm:SetMaterial("Debug/hsv")			
				end
			end
			
		end
		end
		
	end
end
 
function SWEP:DrawWorldModel()
	local offset, rotate
if not IsValid( self.Owner ) then
self:DrawModel( )
return
end


	
		if (self.ShowWorldModel == nil or self.ShowWorldModel) then
			self:DrawModel()
		end
		
		if (!self.WElements) then return end
		
		if (!self.wRenderOrder) then

			self.wRenderOrder = {}

			for k, v in pairs( self.WElements ) do
				if (v.type == "Model") then
					table.insert(self.wRenderOrder, 1, k)
				elseif (v.type == "Sprite" or v.type == "Quad") then
					table.insert(self.wRenderOrder, k)
				end
			end

		end
		
		if (IsValid(self.Owner)) then
			bone_ent = self.Owner
		else
			-- // when the weapon is dropped
			bone_ent = self
		end
		
		for k, name in pairs( self.wRenderOrder ) do
		
			local v = self.WElements[name]
			if (!v) then self.wRenderOrder = nil break end
			if (v.hide) then continue end
			
			local pos, ang
			
			if (v.bone) then
				pos, ang = self:GetBoneOrientation( self.WElements, v, bone_ent )
			else
				pos, ang = self:GetBoneOrientation( self.WElements, v, bone_ent, "ValveBiped.Bip01_R_Hand" )
			end
			
			if (!pos) then continue end
			
			local model = v.modelEnt
			local sprite = v.spriteMaterial
			
			if (v.type == "Model" and IsValid(model)) then

				model:SetPos(pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z )
				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)

				model:SetAngles(ang)
				-- //model:SetModelScale(v.size)
				local matrix = Matrix()
				matrix:Scale(v.size)
				model:EnableMatrix( "RenderMultiply", matrix )
				
				if (v.material == "") then
					model:SetMaterial("")
				elseif (model:GetMaterial() != v.material) then
					model:SetMaterial( v.material )
				end
				
				if (v.skin and v.skin != model:GetSkin()) then
					model:SetSkin(v.skin)
				end
				
				if (v.bodygroup) then
					for k, v in pairs( v.bodygroup ) do
						if (model:GetBodygroup(k) != v) then
							model:SetBodygroup(k, v)
						end
					end
				end
				
				if (v.surpresslightning) then
					render.SuppressEngineLighting(true)
				end
				
				render.SetColorModulation(v.color.r/255, v.color.g/255, v.color.b/255)
				render.SetBlend(v.color.a/255)
				model:DrawModel()
				render.SetBlend(1)
				render.SetColorModulation(1, 1, 1)
				
				if (v.surpresslightning) then
					render.SuppressEngineLighting(false)
				end
				
			elseif (v.type == "Sprite" and sprite) then
				
				local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
				render.SetMaterial(sprite)
				render.DrawSprite(drawpos, v.size.x, v.size.y, v.color)
				
			elseif (v.type == "Quad" and v.draw_func) then
				
				local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
				ang:RotateAroundAxis(ang:Up(), v.angle.y)
				ang:RotateAroundAxis(ang:Right(), v.angle.p)
				ang:RotateAroundAxis(ang:Forward(), v.angle.r)
				
				cam.Start3D2D(drawpos, ang, v.size)
					v.draw_func( self )
				cam.End3D2D()

			end
			
		end
		
	end

	function SWEP:GetBoneOrientation( basetab, tab, ent, bone_override )
		
		local bone, pos, ang
		if (tab.rel and tab.rel != "") then
			
			local v = basetab[tab.rel]
			
			if (!v) then return end
			
			-- // Technically, if there exists an element with the same name as a bone
			-- // you can get in an infinite loop. Let's just hope nobody's that stupid.
			pos, ang = self:GetBoneOrientation( basetab, v, ent )
			
			if (!pos) then return end
			
			pos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
			ang:RotateAroundAxis(ang:Up(), v.angle.y)
			ang:RotateAroundAxis(ang:Right(), v.angle.p)
			ang:RotateAroundAxis(ang:Forward(), v.angle.r)
				
		else
		
			bone = ent:LookupBone(bone_override or tab.bone)

			if (!bone) then return end
			
			pos, ang = Vector(0,0,0), Angle(0,0,0)
			local m = ent:GetBoneMatrix(bone)
			if (m) then
				pos, ang = m:GetTranslation(), m:GetAngles()
			end
			
			if (IsValid(self.Owner) and self.Owner:IsPlayer() and 
				ent == self.Owner:GetViewModel() and self.ViewModelFlip) then
				ang.r = -ang.r --// Fixes mirrored models
			end
		
		end
		
		return pos, ang
	end

	function SWEP:CreateModels( tab )

		if (!tab) then return end

		-- // Create the clientside models here because Garry says we can't do it in the render hook
		for k, v in pairs( tab ) do
			if (v.type == "Model" and v.model and v.model != "" and (!IsValid(v.modelEnt) or v.createdModel != v.model) and 
					string.find(v.model, ".mdl") and file.Exists (v.model, "GAME") ) then
				
				v.modelEnt = ClientsideModel(v.model, RENDER_GROUP_VIEW_MODEL_OPAQUE)
				if (IsValid(v.modelEnt)) then
					v.modelEnt:SetPos(self:GetPos())
					v.modelEnt:SetAngles(self:GetAngles())
					v.modelEnt:SetParent(self)
					v.modelEnt:SetNoDraw(true)
					v.createdModel = v.model
				else
					v.modelEnt = nil
				end
				
			elseif (v.type == "Sprite" and v.sprite and v.sprite != "" and (!v.spriteMaterial or v.createdSprite != v.sprite) 
				and file.Exists ("materials/"..v.sprite..".vmt", "GAME")) then
				
				local name = v.sprite.."-"
				local params = { ["$basetexture"] = v.sprite }
				-- // make sure we create a unique name based on the selected options
				local tocheck = { "nocull", "additive", "vertexalpha", "vertexcolor", "ignorez" }
				for i, j in pairs( tocheck ) do
					if (v[j]) then
						params["$"..j] = 1
						name = name.."1"
					else
						name = name.."0"
					end
				end

				v.createdSprite = v.sprite
				v.spriteMaterial = CreateMaterial(name,"UnlitGeneric",params)
				
			end
		end
		
	end
	
	local allbones
	local hasGarryFixedBoneScalingYet = false

	function SWEP:UpdateBonePositions(vm)
		
		if self.ViewModelBoneMods then
			
			if (!vm:GetBoneCount()) then return end
			
			-- // !! WORKAROUND !! --//
			-- // We need to check all model names :/
			local loopthrough = self.ViewModelBoneMods
			if (!hasGarryFixedBoneScalingYet) then
				allbones = {}
				for i=0, vm:GetBoneCount() do
					local bonename = vm:GetBoneName(i)
					if (self.ViewModelBoneMods[bonename]) then 
						allbones[bonename] = self.ViewModelBoneMods[bonename]
					else
						allbones[bonename] = { 
							scale = Vector(1,1,1),
							pos = Vector(0,0,0),
							angle = Angle(0,0,0)
						}
					end
				end
				
				loopthrough = allbones
			end
			//!! ----------- !! --
			
			for k, v in pairs( loopthrough ) do
				local bone = vm:LookupBone(k)
				if (!bone) then continue end
				
				-- // !! WORKAROUND !! --//
				local s = Vector(v.scale.x,v.scale.y,v.scale.z)
				local p = Vector(v.pos.x,v.pos.y,v.pos.z)
				local ms = Vector(1,1,1)
				if (!hasGarryFixedBoneScalingYet) then
					local cur = vm:GetBoneParent(bone)
					while(cur >= 0) do
						local pscale = loopthrough[vm:GetBoneName(cur)].scale
						ms = ms * pscale
						cur = vm:GetBoneParent(cur)
					end
				end
				
				s = s * ms
				//!! ----------- !! --
				
				if vm:GetManipulateBoneScale(bone) != s then
					vm:ManipulateBoneScale( bone, s )
				end
				if vm:GetManipulateBoneAngles(bone) != v.angle then
					vm:ManipulateBoneAngles( bone, v.angle )
				end
				if vm:GetManipulateBonePosition(bone) != p then
					vm:ManipulateBonePosition( bone, p )
				end
			end
		else
			self:ResetBonePositions(vm)
		end
		   
	end
	 
	function SWEP:ResetBonePositions(vm)
		
		if (!vm:GetBoneCount()) then return end
		for i=0, vm:GetBoneCount() do
			vm:ManipulateBoneScale( i, Vector(1, 1, 1) )
			vm:ManipulateBoneAngles( i, Angle(0, 0, 0) )
			vm:ManipulateBonePosition( i, Vector(0, 0, 0) )
		end
		
	end
	
function table.FullCopy( tab )

if (!tab) then return nil end

local res = {}
for k, v in pairs( tab ) do
if (type(v) == "table") then
res[k] = table.FullCopy(v) // recursion ho!
elseif (type(v) == "Vector") then
res[k] = Vector(v.x, v.y, v.z)
elseif (type(v) == "Angle") then
res[k] = Angle(v.p, v.y, v.r)
else
res[k] = v
end
end

return res

end

function SWEP:PrimaryAttack()
if !self:IsValid() or !self.Owner:IsValid() then return;end 
	pos = self.Owner:GetShootPos()
	ang = self.Owner:GetAimVector()
	damagedice = math.Rand(0,1)
	pain = self.Primary.Damage * damagedice

				if SERVER and IsValid(self.Owner) then
						local slash = {}
						slash.start = pos
						slash.endpos = pos + (ang * 70)
						slash.filter = self.Owner
						slash.mins = Vector(-5, -5, 0)
						slash.maxs = Vector(5, 5, 5)
						local slashtrace = util.TraceHull(slash)
						if slashtrace.Hit then
							targ = slashtrace.Entity
							if targ:IsPlayer() or targ:IsNPC() then
									self.Owner:EmitSound("weapons/melee/knife/knife_slash_"..math.random(1,3)..".wav")								
								paininfo = DamageInfo()
								paininfo:SetDamage(pain)
								paininfo:SetDamageType(DMG_SLASH)
								paininfo:SetAttacker(self.Owner)
								paininfo:SetInflictor(self.Weapon)
						  local RandomForce = math.random(0,0)
								paininfo:SetDamageForce(slashtrace.Normal * RandomForce)
								if targ:IsPlayer() then
								targ:ViewPunch( Angle( -10, -20, 0 ) )
								end
							local blood = targ:GetBloodColor()	
						   local fleshimpact		= EffectData()
								fleshimpact:SetEntity(self.Weapon)
								fleshimpact:SetOrigin(slashtrace.HitPos)
								fleshimpact:SetNormal(slashtrace.HitPos)
								if blood >= 0 then
								fleshimpact:SetColor(blood)
								util.Effect("BloodImpact", fleshimpact)
								end
								
								if SERVER then targ:TakeDamageInfo(paininfo) end
							end
						end
					end
	end
				
function SWEP:Grenade()
if !self:IsValid() or !self.Owner:IsValid() then return;end 
if self.GrenadeTimer then return end
if SERVER then
self.Owner:SetSchedule(SCHED_RANGE_ATTACK1)
end
self.GrenadeTimer = true
local classtimer = 1.1
if self.Owner:GetClass() == "npc_metropolice" or self.BaseCombineHoldType then
classtimer = 0.1
end

timer.Simple(classtimer, function()
if !self:IsValid() or !self.Owner:IsValid() then return;end 
	self.GrenadeTimer = false
if !self.Owner:IsCurrentSchedule( SCHED_RANGE_ATTACK1 ) then return end

	aim = self.Owner:GetAimVector()
	side = aim:Cross(Vector(0,0,1))
	up = side:Cross(aim)
	pos = self.Owner:GetShootPos() + side * 5 + up * 1
	if SERVER then
	local rocket = ents.Create("ent_knife")
	if !rocket:IsValid() then return false end
	rocket:SetAngles(aim:Angle()+Angle(90,90,0))
	rocket:SetPos(pos)
	rocket:SetOwner(self.Owner)
	rocket:Spawn()
	local phys = rocket:GetPhysicsObject()
	local enemypos = 200
	if !self.Owner:GetEnemy() then return end
	if self.Owner:GetEnemy():GetPos():Distance(self:GetPos()) > 900 then 
	enemypos = 1500
	end
	if self.Owner:GetEnemy():GetPos():Distance(self:GetPos()) > 750 and self.Owner:GetEnemy():GetPos():Distance(self:GetPos()) <= 900 then
	enemypos = 1000
	end
	if self.Owner:GetEnemy():GetPos():Distance(self:GetPos()) <= 750 and self.Owner:GetEnemy():GetPos():Distance(self:GetPos()) > 400 then
	enemypos = 800
	end
	if self.Owner:GetEnemy():GetPos():Distance(self:GetPos()) <= 400 then
	enemypos = 500
	end
	phys:ApplyForceCenter(self.Owner:GetAimVector() * 6000)
	end
	end)
end

			
---------------------------Cloak------------------------------------------

-------------------------------Decloak-------------------------------

function SWEP:IsBaseCombineHoldType()
self.BaseCombineHoldType = true
end


function SWEP:ChaseFailed()
self.FailedChase = true
end


