Local Script - Repel


--[[

	Made by GameFlame232 (discord: gameflame_)

	Have Fun!

]]

task.wait(2) -- make sure all blocks are loaded

--<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

--// Services
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Variables
local plr = Players.LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
local rootPart = char:WaitForChild("HumanoidRootPart")

local mainGui = plr.PlayerGui:WaitForChild("Main")
local abilities = mainGui:WaitForChild("Abilities")

local repelOn = true
local cam = workspace.CurrentCamera
local keyHeld = nil
local BlockOffPos = {}
local cooldowns = {}

--<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

--// Settings

--Setup
local indicatorFolder = workspace:WaitForChild("Indicators")
local customBlocks = CollectionService:GetTagged("CustomBlock") -- Table with effected instances
local blastProjectile = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Projectile")

--Main
local globalMinHeight = 3
local minHeightBuffer = 2
local globalMaxHeight = 100
local maxHeightBuffer = 2
local rotationBuffer = 180

local repelDistance = 25
local plrRange = 20
local reqReturnDistance = 35

local repealSpeed = 10 -- distance/speedModifier
local repelEasing = Enum.EasingStyle.Quart

-- Hotkeys
local toggleRepelKey = Enum.KeyCode.Z
local throwKey = Enum.KeyCode.X
local blastKey = Enum.KeyCode.C
local explosionKey = Enum.KeyCode.V

--Throw
local throwCooldown = 5
local throwRadius = 40
local throwSpeed = 15 -- distance/throwSpeed
local throwEasing = Enum.EasingStyle.Sine

--Blast
local blastCooldown = 2
local blastSpeed = 2
local blastDistance = 100
local blastEasing = Enum.EasingStyle.Linear

--Explosion
local explosionCooldown = 10
local explosionRadius = 80

--<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

--// Display
local statusDisplay = {
	["Repel"] = abilities:WaitForChild("Repel"):WaitForChild("Status"),
	["Throw"] = abilities:WaitForChild("Throw"):WaitForChild("Status"),
	["Blast"] = abilities:WaitForChild("Blast"):WaitForChild("Status"),
	["Explosion"] = abilities:WaitForChild("Explosion"):WaitForChild("Status"),
}
abilities.Repel:WaitForChild("Key").Text = toggleRepelKey.Name
abilities.Throw:WaitForChild("Key").Text = throwKey.Name
abilities.Blast:WaitForChild("Key").Text = blastKey.Name
abilities.Explosion:WaitForChild("Key").Text = explosionKey.Name
statusDisplay.Repel.Text = if repelOn then "On" else "Off"

local function ShowCooldown(textLabel, cooldown)
	textLabel.Text = cooldown
	
	repeat
		task.wait(1)
		cooldown -= 1
		textLabel.Text = math.round(cooldown)
	until cooldown <= 0
	
	textLabel.Text = "Ready"
	
end

--<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

--// Key Functions

local function Repel(center, block)
	
	local blockPos = block.Position
	local direction = (blockPos - center).Unit
	local TargetPos = (direction * repelDistance) + blockPos
	
	-- If target Pos is below or above the limit then use the buffer
	if TargetPos.Y < globalMinHeight then
		local newY = globalMinHeight + math.random(0, minHeightBuffer)
		TargetPos = Vector3.new(TargetPos.X, newY, TargetPos.Z)
	elseif TargetPos.Y > globalMaxHeight then
		local newY = globalMaxHeight + math.random(0, maxHeightBuffer)
		TargetPos = Vector3.new(TargetPos.X, newY, TargetPos.Z)
	end
	
	local speed = (blockPos - TargetPos).Magnitude / repealSpeed

	local rotationX = block.CFrame.Rotation.X + math.random(0, rotationBuffer)
	local rotationY = block.CFrame.Rotation.Y + math.random(0, rotationBuffer)
	local rotationZ = block.CFrame.Rotation.Z + math.random(0, rotationBuffer)
	
	local blockTween = TweenService:Create(block, TweenInfo.new(speed, repelEasing), {CFrame = CFrame.new(TargetPos) * CFrame.Angles(rotationX, rotationY, rotationZ)})

	if BlockOffPos[block] then
		BlockOffPos[block].IsMoving = true
		BlockOffPos[block].Tween:Cancel()
		BlockOffPos[block].Tween = blockTween
	else
		BlockOffPos[block] = {
			OriginalPos = blockPos, 
			OriginalRot = block.CFrame.LookVector,
			IsMoving = true,
			ForcedTrave = false,
			Tween = blockTween}
	end

	block.CanCollide = false
	blockTween:Play()
	
	blockTween.Completed:Connect(function()
		if block.Position == TargetPos then
			BlockOffPos[block].IsMoving = false
		end
	end)
end

local function Return(block)
	if not BlockOffPos[block] then return end

	BlockOffPos[block].IsMoving = true
	
	local originalPos = BlockOffPos[block].OriginalPos
	local originalRot = BlockOffPos[block].OriginalRot
	
	local speed = (block.Position - originalPos).Magnitude / repealSpeed
	
	local blockTween = TweenService:Create(block, TweenInfo.new(speed, repelEasing), {CFrame = CFrame.lookAlong(originalPos, originalRot)})
	
	BlockOffPos[block].Tween:Cancel()
	BlockOffPos[block].Tween = blockTween
	
	blockTween:Play()
	
	blockTween.Completed:Connect(function()
		if block.Position == BlockOffPos[block].OriginalPos then
			BlockOffPos[block] = nil
			block.CanCollide = true
		end
	end)
end

local function CheckDistance(centerPos : Vector3, blockTable)
	
	local centerPosition = rootPart.Position

	-- Loops through all blocks with the "customBlock" Tag
	for _, block in pairs(customBlocks) do
		if not block:IsA("BasePart") then continue end
		if BlockOffPos[block] and BlockOffPos[block].ForcedTrave then continue end
		
		local distance = (block.Position - centerPos).Magnitude
		
		-- If block is close enough to the player then push it away
		if distance <= plrRange then
			Repel(centerPos, block)
		elseif distance >= reqReturnDistance then
			if not BlockOffPos[block] then continue end
			if BlockOffPos[block].IsMoving then continue end
			Return(block)
		end
		
	end

end

local function CreateRadius(placement : Vector3, diameter)
	
	local newRadius = Instance.new("Part")
	newRadius.Name = "Radius"
	newRadius.Shape = Enum.PartType.Ball
	newRadius.Size = Vector3.new(diameter,diameter,diameter)
	newRadius.Material = Enum.Material.ForceField
	newRadius.Color = Color3.new(0,1,1)
	newRadius.Transparency = 0.5
	newRadius.CanCollide = false
	newRadius.CastShadow = false
	newRadius.Anchored = true
	newRadius.Position = placement
	newRadius.Parent = indicatorFolder
	
	return newRadius
end

local function MouseRay(params)
	local mousePosition = UserInputService:GetMouseLocation()
	local mouseRay = cam:ViewportPointToRay(mousePosition.X,mousePosition.Y)
	local raycasResult = workspace:Raycast(mouseRay.Origin, mouseRay.Direction * 1000, params)

	return raycasResult, mouseRay.Origin, mouseRay.Direction
end

--// Abilities

local function ThrowHold()
	local indicator = CreateRadius(rootPart.Position, throwRadius*2)
	
	repeat
		indicator.Position = rootPart.Position
		task.wait()
	until keyHeld ~= throwKey
	
	indicator:Destroy()
	
end
local function ThrowRelease()

	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {indicatorFolder}

	local mouseRay = MouseRay(rayParams)
	if not mouseRay then return end

	for _, block in pairs(customBlocks) do
		
		if not block:IsA("BasePart") then continue end

		local distance = (block.Position - rootPart.Position).Magnitude
		
		if distance <= throwRadius then
			
			local blockTween = TweenService:Create(block, TweenInfo.new(distance/throwSpeed, throwEasing), {Position = mouseRay.Position})
			
			if BlockOffPos[block] then
				BlockOffPos[block].ForcedTrave = true
				BlockOffPos[block].IsMoving = true
				BlockOffPos[block].Tween:Cancel()
				BlockOffPos[block].Tween = blockTween
			else
				BlockOffPos[block] = {
					OriginalPos = block.Position, 
					OriginalRot = block.CFrame.LookVector,
					IsMoving = true,
					ForcedTrave = true,
					Tween = blockTween}
			end
			
			blockTween:Play()
			blockTween.Completed:Connect(function()
				if not BlockOffPos[block] then return end
				BlockOffPos[block].ForcedTrave = false
				BlockOffPos[block].IsMoving = false
			end)
			
		end
		
	end

end

local function BlastHold()
	local indicator = CreateRadius(rootPart.Position, 5)

	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {indicatorFolder}

	repeat
		task.wait()
		
		local mouseRay = MouseRay(rayParams)
		if not mouseRay then indicator.Transparency = 1 continue end
		indicator.Transparency = 0.5
		
		indicator.Position = mouseRay.Position
	until keyHeld ~= blastKey

	indicator:Destroy()
end
local function BlastRelease()
	
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {indicatorFolder}

	local mouseRay, direction = MouseRay(rayParams)
	if not mouseRay then return end

	local travel = (mouseRay.Position - rootPart.Position).Unit * blastDistance

	local newProjectile = blastProjectile:Clone()
	newProjectile.CanCollide = false
	newProjectile.Anchored = true
	newProjectile.Position = rootPart.Position
	newProjectile.Parent = indicatorFolder
	
	local shootTween = TweenService:Create(newProjectile, TweenInfo.new(blastSpeed, blastEasing), {Position = rootPart.Position + travel})
	shootTween:Play()
	
	repeat
		task.wait()
		
		CheckDistance(newProjectile.Position, customBlocks)
	
	until shootTween.PlaybackState == Enum.PlaybackState.Completed
	
	newProjectile:Destroy()
	
end

local function ExplodeHold()
	local indicator = CreateRadius(rootPart.Position, explosionRadius*2)

	repeat
		indicator.Position = rootPart.Position
		task.wait()
	until keyHeld ~= explosionKey

	indicator:Destroy()
end
local function ExplodeRelease()
	
	local oldPlrRange = plrRange
	plrRange = explosionRadius
	CheckDistance(rootPart.Position, customBlocks)
	task.wait(1)
	plrRange = oldPlrRange
	
end


UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if keyHeld then return end
	if input.KeyCode ~= toggleRepelKey and input.KeyCode ~= throwKey and input.KeyCode ~= blastKey and input.KeyCode ~= explosionKey then return end
	
	keyHeld = input.KeyCode
	
	if input.KeyCode == toggleRepelKey then
		repelOn = not repelOn
		statusDisplay.Repel.Text = if repelOn then "On" else "Off"
	elseif input.KeyCode == throwKey then
		if cooldowns["Throw"] and cooldowns["Throw"] + throwCooldown >= tick() then return end
		ThrowHold()
	elseif input.KeyCode == blastKey then
		if cooldowns["Blast"] and cooldowns["Blast"] + throwCooldown >= tick() then return end
		BlastHold()
	elseif input.KeyCode == explosionKey then
		if cooldowns["Explosion"] and cooldowns["Explosion"] + throwCooldown >= tick() then return end
		ExplodeHold()
	end
	
end)

UserInputService.InputEnded:Connect(function(input, processed)
	if processed then return end
	if not keyHeld then return end
	if input.KeyCode ~= keyHeld then return end
	
	keyHeld = nil

	if input.KeyCode == throwKey then
		if cooldowns["Throw"] and cooldowns["Throw"] + throwCooldown >= tick() then return end
		cooldowns["Throw"] = tick()
		ThrowRelease()
		ShowCooldown(statusDisplay.Throw, throwCooldown)
	elseif input.KeyCode == blastKey then
		if cooldowns["Blast"] and cooldowns["Blast"] + throwCooldown >= tick() then return end
		cooldowns["Blast"] = tick()
		BlastRelease()
		ShowCooldown(statusDisplay.Blast, blastCooldown)
	elseif input.KeyCode == explosionKey then
		if cooldowns["Explosion"] and cooldowns["Explosion"] + throwCooldown >= tick() then return end
		cooldowns["Explosion"] = tick()
		ExplodeRelease()
		ShowCooldown(statusDisplay.Explosion, explosionCooldown)
	end
end)

RunService.Heartbeat:Connect(function()
	if repelOn then
		CheckDistance(rootPart.Position, customBlocks)
	else
		for _, block in pairs(customBlocks) do
			if not block:IsA("BasePart") then continue end
			if not BlockOffPos[block] then continue end
			if BlockOffPos[block].ForcedTrave then continue end
			if BlockOffPos[block].IsMoving then continue end
			Return(block)
		end
	end
end)