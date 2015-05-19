--
-- Author: Zhang Dongli
-- Date: 2015-05-18 22:09:09
--

local MeshScene = class("MeshScene", function()
    return display.newScene("MeshScene")
end);

function MeshScene:ctor()
	--数据
	self.zhangAis = {};
	self.wangGes = {};

	--颜色
	self.m_zhangAiColor = cc.c4f(1, 0, 0, 1);
	self.m_wangGeColor = cc.c4f(0, 1, 0, 1);

	--初始化地图
	self.m_mapLayer = cc.NodeGrid:create();
	self:addChild(self.m_mapLayer);
	self:initMap();

	--初始化绘图
	self.m_drawWangGeNode = display.newDrawNode();
	self:addChild(self.m_drawWangGeNode);
	
	self.m_drawZhangAiNode = display.newDrawNode();
	self:addChild(self.m_drawZhangAiNode);

	--初始化UI界面
	self.m_uiLayer = display.newLayer();
	self:addChild(self.m_uiLayer);
	self:initUI();


	--开启刷新
    self:addNodeEventListener(cc.NODE_ENTER_FRAME_EVENT,function(dt)
    	self:update(dt);
	end);
	self:scheduleUpdate();
end

function MeshScene:update()
	self.m_drawZhangAiNode:clear();
	self.m_drawWangGeNode:clear();

	self:drawZhangAi();
	self:drawWangGe();
end

------------------------------------------------------------
-- 初始化
------------------------------------------------------------

function MeshScene:initMap()
	local tmxTiledMap = cc.TMXTiledMap:create("maps/moba_caodi.tmx");
	if tmxTiledMap == nil then return end
	self.m_mapLayer:addChild(tmxTiledMap);

	local group = tmxTiledMap:getObjectGroup("zhang_ai_rect");
	if group ~= nil then
		local objs = group:getObjects();
		if objs ~= nil  and #objs > 0 then
			local _x,_y,_polylinePoints;

			for i,obj in ipairs(objs) do
				_x = tonumber(obj["x"]);
				_y = tonumber(obj["y"]);
				_polylinePoints = obj["polylinePoints"];
				if _polylinePoints ~= nil and #_polylinePoints > 0 then
					local points = {};
					for j,point in ipairs(_polylinePoints) do
						if j ~= #_polylinePoints then
							points[#points + 1] = cc.p( _x + tonumber(point["x"]) , _y - tonumber(point["y"]) );
						end
					end
					if #points > 2 then
						local polygon = MobaPolygon.Polygon(points); 
						self.zhangAis[#self.zhangAis + 1] = polygon
					end
				end
			end
		end
	end
end

function MeshScene:initUI()
	--生成按钮
	self.shengChengBtn =  cc.ui.UIPushButton.new({["normal"]="images/wang_ge_sheng_cheng1.png",
												["pressed"]="images/wang_ge_sheng_cheng2.png",
												["disabled"] = "images/wang_ge_sheng_cheng2.png"});
	self.shengChengBtn:onButtonClicked(handler(self, self.shengChengBtnClick));
	self.shengChengBtn:setPosition(display.width - 100/2,display.height - 56/2 - 56*0);
	self.m_uiLayer:addChild(self.shengChengBtn);

	--保存按钮
	self.baoCunBtn =  cc.ui.UIPushButton.new({["normal"]="images/wang_ge_bao_cun1.png",
												["pressed"]="images/wang_ge_bao_cun2.png",
												["disabled"] = "images/wang_ge_bao_cun2.png"});
	self.baoCunBtn:onButtonClicked(handler(self, self.baoCunBtnClick));
	self.baoCunBtn:setPosition(display.width - 100/2,display.height - 56/2 - 56*1);
	self.baoCunBtn:setButtonEnabled(false);
	self.m_uiLayer:addChild(self.baoCunBtn);
end

------------------------------------------------------------
-- 按钮点击
------------------------------------------------------------

function MeshScene:shengChengBtnClick(sender)
	if self.zhangAis == nil or #self.zhangAis  == 0 then 
		print("障碍不可以为空");
		return;
	end

	local id,groupId = 1,1;
	local res,wangGes = MobaNavMeshGen.sInstance():CreateNavMesh(self.zhangAis,id,groupId);
	if res ~= NavResCode.Success then
		print("生成网格失败");
		return;
	end

	self.wangGes = wangGes;

	self.shengChengBtn:setButtonEnabled(false);
	self.baoCunBtn:setButtonEnabled(true);
end

function MeshScene:baoCunBtnClick(sender)

	if self.wangGes == nil or #self.wangGes  == 0 then 
		print("网格不可以为空");
		return;
	end
	
	-- 写入文件
	local name = "caodi.json";
	local writePath = cc.FileUtils:getInstance():getWritablePath();
	local res = MobaNavMeshGen.sInstance():WriteToFile(writePath..name,self.wangGes);
	if res ~= NavResCode.Success then
		print("写入文件失败");
		return;
	end

	self.shengChengBtn:setButtonEnabled(true);
	self.baoCunBtn:setButtonEnabled(false);
end

------------------------------------------------------------
-- 绘图
------------------------------------------------------------

--[[
	* 绘制障碍
]]
function MeshScene:drawZhangAi()
	if self.zhangAis ~=nil  and #self.zhangAis > 0 then
		for i,poly in ipairs(self.zhangAis) do
			local points = poly:GetPoints();
			self.m_drawZhangAiNode:drawPolygon(points,{fillColor = cc.c4f(0,0,0,0),borderColor = self.m_zhangAiColor,borderWidth = 1})
		end		
	end
end

--[[
	* 绘制网格
]]
function MeshScene:drawWangGe()
	if self.wangGes ~= nil and #self.wangGes > 0 then
		for i,tri in ipairs(self.wangGes) do
			local p1 = cc.p(tri:GetPoint(1).x, tri:GetPoint(1).y);
			local p2 = cc.p(tri:GetPoint(2).x, tri:GetPoint(2).y);
			local p3 = cc.p(tri:GetPoint(3).x, tri:GetPoint(3).y);


			self.m_drawWangGeNode:drawLine(p1, p2, self.m_wangGeColor);
			self.m_drawWangGeNode:drawLine(p2, p3, self.m_wangGeColor);
			self.m_drawWangGeNode:drawLine(p3, p1, self.m_wangGeColor);
		end		
	end
end

return MeshScene;