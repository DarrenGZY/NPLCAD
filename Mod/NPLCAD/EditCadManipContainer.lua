--[[
Title: Edit Cad Manipulator
Author(s): LiXizhi@yeah.net
Date: 2016/11/6
Desc: 
use the lib:
------------------------------------------------------------
NPL.load("(gl)Mod/NPLCAD/EditCadManipContainer.lua");
local EditCadManipContainer = commonlib.gettable("MyCompany.Aries.Game.Manipulators.EditCadManipContainer");
local manipCont = EditCadManipContainer:new();
manipCont:init();
self:AddManipulator(manipCont);
manipCont:connectToDependNode(entity);
------------------------------------------------------------
]]
NPL.load("(gl)script/ide/System/Scene/Manipulators/ManipContainer.lua");
local Plane = commonlib.gettable("mathlib.Plane");
local vector3d = commonlib.gettable("mathlib.vector3d");
local ShapesDrawer = commonlib.gettable("System.Scene.Overlays.ShapesDrawer");
local BlockEngine = commonlib.gettable("MyCompany.Aries.Game.BlockEngine");
local EditCadManipContainer = commonlib.inherit(commonlib.gettable("System.Scene.Manipulators.ManipContainer"), commonlib.gettable("MyCompany.Aries.Game.Manipulators.EditCadManipContainer"));
EditCadManipContainer:Property({"Name", "EditCadManipContainer", auto=true});
-- EditCadManipContainer:Property({"EnablePicking", true});
EditCadManipContainer:Property({"PenWidth", 0.01});
EditCadManipContainer:Property({"showGrid", true, "IsShowGrid", "SetShowGrid", auto=true});
EditCadManipContainer:Property({"mainColor", "#ffff00"});
-- attribute name for position on the dependent node that we will bound to. it should be vector3d type like {0,0,0}
EditCadManipContainer:Property({"PositionPlugName", "position", auto=true});
EditCadManipContainer:Property({"ScalePlugName", "scale", auto=true});
EditCadManipContainer:Property({"YawPlugName", "yaw", auto=true});

function EditCadManipContainer:ctor()
	self:AddValue("position", {0,0,0});
end

function EditCadManipContainer:createChildren()
	self.scaleManip = self:AddScaleManip();
	self.scaleManip:SetUniformScaling(true);
	self.rotateManip = self:AddRotateManip();
	self.rotateManip:SetYawPitchRollMode(true);
	self.rotateManip:SetYawEnabled(true);
	self.rotateManip:SetPitchEnabled(false);
	self.rotateManip:SetRollEnabled(false);
	-- TODO: support translate?
	--self.translateManip = self:AddTranslateManip();
end

function EditCadManipContainer:paintEvent(painter)
	EditCadManipContainer._super.paintEvent(self, painter);
end

function EditCadManipContainer:OnValueChange(name, value)
	EditCadManipContainer._super.OnValueChange(self);
	if(name == "position") then
		self:SetPosition(unpack(value));
	end
end

-- @param node: it should be EntityBlockModel object. 
function EditCadManipContainer:connectToDependNode(node)
	local plugPos = node:findPlug(self.PositionPlugName);
	local plugScale = node:findPlug(self.ScalePlugName);
	local plugYaw = node:findPlug(self.YawPlugName);

	self.node = node;

	if(plugPos) then
		-- one way binding 
		local manipPosPlug = self:findPlug("position");
		self:addPlugToManipConversionCallback(manipPosPlug, function(self, manipPlug)
			return plugPos:GetValue():clone();
		end);

		-- two-way binding for scaling conversion:
		if(plugScale) then
			local manipScalePlug = self.scaleManip:findPlug("scaling");
			self:addManipToPlugConversionCallback(plugScale, function(self, plug)
				return manipScalePlug:GetValue()[1] or 1;
			end);
			self:addPlugToManipConversionCallback(manipScalePlug, function(self, manipPlug)
				local scaling = plugScale:GetValue() or 1;
				if(type(scaling) == "number") then
					scaling = {scaling, scaling, scaling};
				end
				return scaling;
			end);
		end

		-- two-way binding for yaw conversion:
		if(plugYaw) then
			local manipYawPlug = self.rotateManip:findPlug("yaw");
			self:addManipToPlugConversionCallback(plugYaw, function(self, plug)
				return manipYawPlug:GetValue() or 0;
			end);
			self:addPlugToManipConversionCallback(manipYawPlug, function(self, manipPlug)
				return plugYaw:GetValue() or 0;
			end);
		end

		-- force Begin/End edit pairs for updating result to network.
		if(node.BeginEdit) then
			node:BeginEdit();
			self:Connect("beforeDestroyed", node, "EndEdit"); 
		end
	end
	-- should be called only once after all conversion callbacks to setup real connections
	self:finishAddingManips();
	EditCadManipContainer._super.connectToDependNode(self, node);
end