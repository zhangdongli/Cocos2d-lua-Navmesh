
local MainScene = class("MainScene", function()
    return display.newScene("MainScene")
end)

------------------------------------------------------
-- 生命周期
------------------------------------------------------

function MainScene:ctor()
	
	-- 数据
	self.allBlockPolygons = {};				--所有不可通过对变形集合
	self.currentBlockPolygonPoints = {};    --当前不可通过多边形定点集合

	self.startPos = cc.p(0,0); 				--寻路起始点
	self.endPos = cc.p(0,0); 				--寻路结束点

	self.wanGes = {}; 						--生成的网格
	self.luJingPoints = {}; 				--生成的路径点

	-- 标志
	self.isSheZhiZhangAi = true;            --是否是设置障碍状态 默认true
	self.isSheZhiLuJing = false; 			--是否是设置路径状态 

	self.isDrawZhangAi = true; 				--是否绘制障碍
	self.isDrawWangGe = true; 				--是否绘制网格
	self.isDrawLuJing = true; 				--是否绘制路径	

	--颜色
	self.currZhangAiColor = cc.c4f(1,1,1,1);
	self.currLuJingDianColor = cc.c4f(250/255.0,202/255.0,13/255.0,1);

	self.zhangAiColor = cc.c4f(1,0,0,1);
	self.wanGeColor = cc.c4f(0,1,0,1);
	self.luJingColor = cc.c4f(0,0,1,1);


    --绘图层
    self.drawWanGeNode = display.newDrawNode();
    self:addChild(self.drawWanGeNode,1);

    self.drawZhangAiNode = display.newDrawNode();
    self:addChild(self.drawZhangAiNode,2);
    
    self.drawLuJingNode = display.newDrawNode();
    self:addChild(self.drawLuJingNode,3);

    self.drawCurrentNode = display.newDrawNode();
    self:addChild(self.drawCurrentNode,4);

    --触摸层
    self.touchLayer = display.newLayer();
    self:addChild(self.touchLayer,5);
    self:initTouch();

    --ui层
    self.uiNode = display.newNode();
    self:addChild(self.uiNode,6);
    self:initUI();

    --开启刷新
    self:addNodeEventListener(cc.NODE_ENTER_FRAME_EVENT,function(dt)
    	self:update(dt);
	end);
	self:scheduleUpdate();

	-- 从文件读取
	-- local readPath = cc.FileUtils:getInstance():getWritablePath();
	-- local res,triLs = MobaNavMeshGen.sInstance():ReadFormFile(readPath.."caodi.json");
	-- if res == NavResCode.Success then
	-- 	self.wanGes = triLs;

	-- 	self.isSheZhiZhangAi = false;            --是否是设置障碍状态
	-- 	self.isSheZhiLuJing = true; 			 --是否是设置路径状态 

	-- 	self.shengChengWangGeBtn:setButtonEnabled(false);
	-- 	self.shengChengLuJingBtn:setButtonEnabled(true);
	-- end
end

function MainScene:onEnter()
end

function MainScene:onExit()
end

--[[
	* 刷新函数
]]
function MainScene:update(dt)
	self.drawZhangAiNode:clear();
    self.drawWanGeNode:clear();
    self.drawLuJingNode:clear();
    self.drawCurrentNode:clear();
	
	self:drawLuJingDian();
	self:drawCurrentZhangAi();

	self:drawZhangAi();
	self:drawWanGe();
	self:drawLuJing();
end

------------------------------------------------------
-- 初始化
------------------------------------------------------

--[[
	* 初始化数据
]]
function MainScene:initData()
	self.allBlockPolygons = {};				--所有不可通过对变形集合
	self.currentBlockPolygonPoints = {};    --当前不可通过多边形定点集合

	self.startPos = cc.p(0,0); 				--寻路起始点
	self.endPos = cc.p(0,0); 				--寻路结束点

	self.wanGes = {}; 						--生成的网格
	self.luJingPoints = {}; 				--生成的路径点

	-- 标志
	self.isSheZhiZhangAi = true;            --是否是设置障碍状态 默认true
	self.isSheZhiLuJing = false; 			--是否是设置路径状态 


	-- 按钮
	if self.shengChengWangGeBtn then
		self.shengChengWangGeBtn:setButtonEnabled(true);
	end

	if self.shengChengLuJingBtn then
		self.shengChengLuJingBtn:setButtonEnabled(false);
	end
end


--[[
	* 初始化触摸
]]
function MainScene:initTouch()
    self.touchLayer:setTouchEnabled(true)
    self.touchLayer:addNodeEventListener(cc.NODE_TOUCH_EVENT,function(event)
    	if event.name ==  "began" then
    		return self:onTouchBegan(event);
    	elseif event.name == "ended" then 
    		self:onTouchEnded(event);
    	end
    end)
end

--[[
	* 初始化UI
]]
function MainScene:initUI()

	--生成网格按钮
	self.shengChengWangGeBtn =  cc.ui.UIPushButton.new({["normal"]="images/sheng_cheng_wang_ge1.png",
												["pressed"]="images/sheng_cheng_wang_ge2.png",
												["disabled"] = "images/sheng_cheng_wang_ge2.png"});
	self.shengChengWangGeBtn:onButtonClicked(handler(self, self.shengChengWangGeClick));
	self.shengChengWangGeBtn:setPosition(120/2+0*120,display.height - 56/2);
	self.uiNode:addChild(self.shengChengWangGeBtn);

	--生成路径按钮
	self.shengChengLuJingBtn =  cc.ui.UIPushButton.new({["normal"]="images/sheng_cheng_lu_jing1.png",
												["pressed"]="images/sheng_cheng_lu_jing2.png",
												["disabled"] = "images/sheng_cheng_lu_jing2.png"});
	self.shengChengLuJingBtn:onButtonClicked(handler(self, self.shengChengLuJingClick));
	self.shengChengLuJingBtn:setPosition(120/2+1*120,display.height - 56/2);
	self.shengChengLuJingBtn:setButtonEnabled(false);
	self.uiNode:addChild(self.shengChengLuJingBtn);

	--完成按钮
	self.wanChengBtn =  cc.ui.UIPushButton.new({["normal"]="images/wan_cheng1.png",
												["pressed"]="images/wan_cheng2.png",
												["disabled"] = "images/wan_cheng2.png"});
	self.wanChengBtn:onButtonClicked(handler(self, self.wanChengClick));
	self.wanChengBtn:setPosition(display.width - 85/2,display.height - 56/2);
	self.wanChengBtn:setButtonEnabled(true);
	self.uiNode:addChild(self.wanChengBtn);
end

------------------------------------------------------
-- ui事件
------------------------------------------------------

--[[
	* 生成网格按钮点击
]]
function MainScene:shengChengWangGeClick(event)
	print("生成网格按钮点击");

	if #self.allBlockPolygons <= 0 then 
		print("请前设置好障碍后，再生成网格");
		return;
	end

	local id,groupId = 1,1;
	local res,wanGes = MobaNavMeshGen.sInstance():CreateNavMesh(self.allBlockPolygons,id,groupId);
	if res == NavResCode.Success then
		print("生成网格成功",#wanGes);

		-- 保存障碍
		self.wanGes = wanGes;

		--进入寻路状态
		self.isSheZhiZhangAi = false;
		self.isSheZhiLuJing = true; 

		self.shengChengWangGeBtn:setButtonEnabled(false);
		self.shengChengLuJingBtn:setButtonEnabled(true);

		-- 写入文件
		-- local writePath = cc.FileUtils:getInstance():getWritablePath();
		-- MobaNavMeshGen.sInstance():WriteToFile(writePath.."wange.json",wanGes);	

	else
		print("生成导航网格失败");	
	end
end

--[[
	* 生成路径按钮点击
]]
function MainScene:shengChengLuJingClick(event)
	print("生成路径按钮点击");

	if MobaNMath.PointIsEqualZero(self.startPos) or MobaNMath.PointIsEqualZero(self.endPos) then
		print("请设置起点和终点");
		return;
	end

	local lst = {};
	for i,item in ipairs(self.wanGes) do
		local navTri = item:CloneNavTriangle();
		lst[#lst + 1] = navTri;
	end
	
	MobaNavSeeker.GetInstance():setNavMeshData(lst);
	local res,lstpath = MobaNavSeeker.GetInstance():Seek(self.startPos ,self.endPos, 1);
	if PathResCode.Success == res then
		print("生成路径成功",#lstpath);
		self.luJingPoints = lstpath;
		self.startPos = cc.p(0,0);
		self.endPos = cc.p(0,0);
	else
		print("生成路径失败");
		self.luJingPoints = {};	
	end
end

--[[
	* 完成按钮点击
]]
function MainScene:wanChengClick(event)
	print("完成按钮点击");
	
	if self.isSheZhiZhangAi then
		if #self.currentBlockPolygonPoints < 3 then
			print("点的个数构不成多边形");
			return;
		end

		-- 生成多边形
		local polygon = MobaPolygon.Polygon(clone(self.currentBlockPolygonPoints));

		-- 添加到障碍多边形集合中
		self.allBlockPolygons[#self.allBlockPolygons + 1] = polygon;

		-- 清空当前点
		self.currentBlockPolygonPoints = {};
	elseif self.isSheZhiLuJing then
		-- 重新来过
		self:initData();		
	end
end

------------------------------------------------------
-- 触摸事件
------------------------------------------------------

--[[
	* 触摸开始
]]
function MainScene:onTouchBegan(event)
	local childs = self.uiNode:getChildren();
	for i,child in ipairs(childs) do
		if child:getCascadeBoundingBox():containsPoint(cc.p(event.x,event.y)) then
			return false;
		end
	end
	print("触摸开始");
	return true;
end

--[[
	* 触摸结束
]]
function MainScene:onTouchEnded(event)
	print("触摸结束");

	if self.isSheZhiZhangAi then
		-- 添加一个定点
		self.currentBlockPolygonPoints[#self.currentBlockPolygonPoints + 1] = cc.p(event.x,event.y);
	elseif self.isSheZhiLuJing  then
		if self.startPos.x == 0 and self.startPos.y == 0 then --第一下为起点
			self.startPos = cc.p(event.x,event.y);
		elseif self.endPos.x == 0 and self.endPos.y == 0 then --第二下为结束点
			self.endPos = cc.p(event.x,event.y);
		else
			self.endPos = cc.p(event.x,event.y); --之后都为结束点		
		end	
	end	
end



------------------------------------------------------
-- 绘图
------------------------------------------------------

--[[
	* 绘制路径点
]]
function MainScene:drawLuJingDian()
	if self.startPos.x > 0 and self.startPos.y > 0 then
		self.drawCurrentNode:drawDot(self.startPos,2,self.currLuJingDianColor);
	end 

	if self.endPos.x > 0 and self.endPos.y > 0 then
		self.drawCurrentNode:drawDot(self.endPos,2,self.currLuJingDianColor);
	end
end

--[[
	* 绘制当前设置障碍
]]
function MainScene:drawCurrentZhangAi()
	if #self.currentBlockPolygonPoints >= 2 then
		local sP = self.currentBlockPolygonPoints[1];
		local eP = nil;
		for i=2,#self.currentBlockPolygonPoints do
			ep = self.currentBlockPolygonPoints[i];
			self.drawCurrentNode:drawLine(sP, ep, self.currZhangAiColor);
			sP = ep;
		end
		if #self.currentBlockPolygonPoints > 2 then
			ep = self.currentBlockPolygonPoints[1];
			self.drawCurrentNode:drawLine(sP, ep, self.currZhangAiColor);
		end
	end
end

--[[
	* 绘制障碍
]]
function MainScene:drawZhangAi()
	if self.isDrawZhangAi  and self.allBlockPolygons ~= nil then
		for i,poly in ipairs(self.allBlockPolygons) do
			local points = poly:GetPoints();
			self.drawZhangAiNode:drawPolygon(points,{fillColor = cc.c4f(0,0,0,0),borderColor = self.zhangAiColor,borderWidth = 1})
		end		
	end
end

--[[
	* 绘制网格
]]
function MainScene:drawWanGe()
	if self.isDrawWangGe and self.wanGes ~= nil then
		for i,tri in ipairs(self.wanGes) do
			local p1 = cc.p(tri:GetPoint(1).x, tri:GetPoint(1).y);
			local p2 = cc.p(tri:GetPoint(2).x, tri:GetPoint(2).y);
			local p3 = cc.p(tri:GetPoint(3).x, tri:GetPoint(3).y);


			self.drawWanGeNode:drawLine(p1, p2, self.wanGeColor);
			self.drawWanGeNode:drawLine(p2, p3, self.wanGeColor);
			self.drawWanGeNode:drawLine(p3, p1, self.wanGeColor);
		end		
	end
end

--[[
	* 绘制路径
]]
function MainScene:drawLuJing()
	if self.isDrawLuJing and self.luJingPoints ~= nil and  #self.luJingPoints > 1 then
		local sP = self.luJingPoints[1];
		local eP = nil;
		for i=2,#self.luJingPoints do
			ep = self.luJingPoints[i];
			self.drawLuJingNode:drawLine(sP, ep, self.luJingColor);
			sP = ep;
		end		
	end
end

return MainScene
