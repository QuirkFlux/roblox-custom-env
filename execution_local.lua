local Players = game:GetService("Players")

local Assets = script.Parent.Parent:FindFirstChild("Assets")
local Modules = Assets:FindFirstChild("Modules")

if not Assets or not Modules then
	error("Assets or Modules not found")
end

local ConfirmEvent = Assets:FindFirstChild("ConfirmEvent")

if not ConfirmEvent then
	error("ConfirmEvent not found")
end

local Highlight = require(Modules:FindFirstChild("Highlight"))
local Dragify = require(Modules:FindFirstChild("Dragify"))

local ConfirmButton = script.Parent:FindFirstChild("Confirm")
local ClearButton = script.Parent:FindFirstChild("Clear")
local TransformButton = script.Parent:FindFirstChild("Transform")

-- Debugging output to verify button references
print("ConfirmButton:", ConfirmButton)
print("ClearButton:", ClearButton)
print("TransformButton:", TransformButton)

if not ConfirmButton or not ConfirmButton:IsA("TextButton") then
	warn("ConfirmButton (Execute) not found or not a TextButton")
end

if not ClearButton or not ClearButton:IsA("TextButton") then
	warn("ClearButton not found or not a TextButton")
end

if not TransformButton or not TransformButton:IsA("TextButton") then
	warn("TransformButton not found or not a TextButton")
end

local Player = Players.LocalPlayer

-- Apply Dragify and Highlight if script.Parent exists
if script.Parent then
	Dragify(script.Parent)
	Highlight(script.Parent.Editor.EditorFrame)
end

-- Connections
if ConfirmButton then
	ConfirmButton.MouseButton1Click:Connect(function()
		--print("ConfirmButton clicked") -- Debugging output
		local sourceText = script.Parent.Editor.EditorFrame.Source.Text
		--print("Source Text:", sourceText) -- Debugging output
		if sourceText == "" then
			print("Source text is empty, no output")
			return
		end
		ConfirmEvent:FireServer(sourceText)
		--print("ConfirmEvent fired with sourceText") -- Debugging output
	end)
end

if ClearButton then
	ClearButton.MouseButton1Click:Connect(function()
		--print("ClearButton clicked") -- Debugging output
		script.Parent.Editor.EditorFrame.Source.Text = ""
	end)
end

if TransformButton then
	TransformButton.MouseButton1Click:Connect(function()
		--print("TransformButton clicked") -- Debugging output
		ConfirmEvent:FireServer("transform")
		--print("ConfirmEvent fired with transform") -- Debugging output
	end)
end
