--
-- Author: Zhang Dongli
-- Date: 2015-05-17 16:14:30
-- Navigation Mesh 寻路者

PathResCode = {
        Success = 0,    			--寻路成功
        Failed = -1,    			--寻路失败
        NoMeshData = -2,   			--没有数据
        NoStartTriOrEndTri = -3,    --没有起始点或终点
        NavIDNotMatch = -4, 		--导航网格的索引和id不匹配
        NotFoundPath = -5,  		--找不到路径
        CanNotGetNextWayPoint = -6, --找不到下一个拐点信息
        GroupNotMatch, 				--起点和中点在不同的孤岛之间，无法到达
        NoCrossPoint,				--没有交点
        FixPointFailed, 			--修复点失败
};

START_POS_EXTEND_LENGTH = 10; 		--起始位置容错长度
END_POS_EXTEND_LENGTH = 2;    		--终点位置容错长度


MobaNavSeeker = class("MobaNavSeeker");

--------------------------------------------------------
-- 获取对象
--------------------------------------------------------

local s_cInstance = nil;
function MobaNavSeeker.GetInstance()
	if s_cInstance == nil then
		s_cInstance = MobaNavSeeker.new();
	end
	return s_cInstance;
end

function MobaNavSeeker:ctor()
	self.m_lstTriangle = nil;    --地图数据
end

--------------------------------------------------------
-- 属性
--------------------------------------------------------

--[[
	* 设置导航数据
]]
function MobaNavSeeker:setNavMeshData(data)
	self.m_lstTriangle = data;
end

--------------------------------------------------------
-- 函数
--------------------------------------------------------

--[[
	* 重置寻路数据
]]
function MobaNavSeeker:ResetData()
	for i,item in ipairs(self.m_lstTriangle) do
		item:Reset();
	end
end

--[[
	* 根据原始点计算出正确的落在导航区内的位置,修复无效点和三角形
	* orgTarTri:起源三角形
	* orgTarPos:起源点
	* otherTri:参考方向三角形
	* otherPos:参考方向点
	* returns:结果
]]
function MobaNavSeeker:FixPos(orgTarTri, orgTarPos, otherTri, otherPos, extendLength)

    local tarPos = orgTarPos;
    --//////////////////////////////////////////////////////////////////////////--
    --为了精确判断,需要逆向延长线段一定长度
    if (extendLength > 0) then
        local newTarPos = MobaNMath.ExtendPos(otherPos, tarPos, extendLength);
        tarPos = newTarPos;
    end
    --//////////////////////////////////////////////////////////////////////////--

    local linePath = MobaLine2D.new(tarPos, otherPos); 	--参考线段
    local lineRect = MobaNMath.LineRect(linePath);   	--获取线段矩形包围盒

    --1)找到所有与参考线段矩形相交的三角形,并判断是否groupID相等
    local crossNavTris = {};
    for i,tri in ipairs(self.m_lstTriangle) do
        if (MobaNMath.CheckCrossByRect(lineRect, tri:GetBoxCollider())) then
            if (otherTri ~= nil and otherTri:GetGroupID() == tri:GetGroupID()) then
            	crossNavTris[#crossNavTris + 1] = tri;
            end	
        end
    end

    --2)找出所有与参考线段相交的三角形,并记录相交点
    local crossPoints = {};    	--相交点列表
    local triIndex = {};  	 	--相交三角形索引列表
    for i,crossTri in ipairs(crossNavTris) do
        local triLine = nil;
        for i=1,3 do
            triLine = MobaLine2D.new(crossTri:GetPoint(i), crossTri:GetPoint((i + 1)%4));
            local res,insPoint = linePath:Intersection(triLine);
            if (res == LineCrossState.CROSS) then
            
                crossPoints[#crossPoints + 1] = insPoint;
                triIndex[#triIndex + 1] = index;
            end
        end
    end

    if (#crossPoints == 0) then
        return PathResCode.NoCrossPoint,orgTarTri,orgTarPos;
    end    


    --3)找到最接近起源点的点
    local lastPos = crossPoints[1];
    local lastTriIndex = triIndex[1];
    local lastLength =  math.pow(lastPos.x - orgTarPos.x, 2.0) + math.pow(lastPos.y - orgTarPos.y, 2.0);
    
    for i=2,#crossPoints do
        local newLength = math.pow(crossPoints[i].x - orgTarPos.x, 2.0) + math.pow(crossPoints[i].y - orgTarPos.y, 2.0);
        if (newLength < lastLength) then
        
            lastPos = crossPoints[i];
            lastTriIndex = triIndex[i];
            lastLength = newLength;
        end
    end

    --4)保存目标
    orgTarPos = lastPos;
    orgTarTri = crossNavTris[lastTriIndex];

    return PathResCode.Success,orgTarTri,orgTarPos;
end

--[[
	* 检查和修复所有错误路径点
	* sTri: 开始三角形
	* startPos:开始点
	* eTri:结束三角形
	* endPos:结束点
	* returns: 检查结果
]]
function MobaNavSeeker:CheckAndFixPos(startTri, startPos, endTri, endPos)

    if ( startTri ~= nil and endTri ~= nil and startTri:GetGroupID() ~= endTri:GetGroupID() ) then 
        return PathResCode.GroupNotMatch,startTri, startPos, endTri, endPos;
    end    

    if (endTri == nil) then
    	local fixRet,endTri,endPos = self:FixPos(endTri,endPos,startTri,startPos,END_POS_EXTEND_LENGTH);
        if (fixRet ~= PathResCode.Success) then
        
            return PathResCode.Failed,startTri, startPos, endTri, endPos;
        end
    end

    if (startTri == nil) then
    
        local fixRet,startTri,startPos = self:FixPos(startTri, startPos, endTri, endPos, START_POS_EXTEND_LENGTH);
    end

    if (startTri == nil or endTri == nil) then
        return PathResCode.Failed,startTri, startPos, endTri, endPos;
    end    

    if (startTri:GetGroupID() ~= endTri:GetGroupID()) then
        return PathResCode.GroupNotMatch,startTri, startPos, endTri, endPos;
    end    

    return PathResCode.Success,startTri, startPos, endTri, endPos;
end

--[[
	* 根据f和h实现排序，A*算法
	* x:
	* y:
	* returns
]]
function MobaNavSeeker:CompareTriWithGValue(x, y)
    local xFvalue = x:GetHValue() --/*+ x.GValue*/;
    local yFvalue = y:GetHValue() --/*+ y.GValue*/;
    return xFvalue > yFvalue;  
end

--[[
	* 寻路路径三角形	
	* strPos: 起始点
	* endPos: 终点
	* offset: 移动物品大小
	* returns1: 结果
	* returns2: 输出路径三角形
]]	
function MobaNavSeeker:SeekTrianglePath(startPos, endPos, offset)

    local pathList = {};
    local startTri,endTri = nil,nil;

    --获得起始与终点三角形
    for i,navTri in ipairs(self.m_lstTriangle) do
        if (startTri == nil) then
            if (navTri:IsPointIn(startPos)) then
                startTri = navTri;
            end    
        end
                
        if (endTri == nil) then
            if (navTri:IsPointIn(endPos)) then
                endTri = navTri;
            end    
        end        

        if (startTri ~= nil and endTri ~= nil) then break end;
    end


    --检查和修复位置
    local posErr,startTri,startPos,endTri,endPos = self:CheckAndFixPos(startTri,startPos,endTri,endPos);
    if (posErr ~= PathResCode.Success) then
        return posErr,startPos,endPos,pathList;
    end    


    --//////////////////////////////////// A*算法 ///////////////////////////////////////--

    local pathSessionId = 1;
    local foundPath = false;
    local openList = {};     --开放列表
    local closeList = {};

    startTri:SetSessionID(pathSessionId);

    openList[#openList + 1] = startTri;
    while (#openList > 0) do
    
        -- 1. 把当前节点从开放列表删除, 加入到封闭列表
        local currNode;
        currNode = openList[1];
        table.remove(openList,1);
        closeList[#closeList + 1] = currNode;

        --已经找到目的地
        if (currNode:GetID() == endTri:GetID()) then
            foundPath = true;
            break;
        end

        -- 2. 对当前节点相邻的每一个节点依次执行以下步骤:
        -- 遍历所有邻接三角型
        for i=1,3 do
        
            local neighborID = currNode:GetNeighbor(i);
            local neighborTri;

            -- 3. 如果该相邻节点不可通行,则什么操作也不执行,继续检验下一个节点;
            if (neighborID > 0) then
            
                neighborTri = self.m_lstTriangle[neighborID];

                if (neighborTri == nil or neighborTri:GetID() ~= neighborID) then
                    return PathResCode.NavIDNotMatch,startPos,endPos,pathList;
                end    

	            if (neighborTri:GetGroupID() == startTri:GetGroupID() ) then
	            
	                if (neighborTri:GetSessionID() ~= pathSessionId) then
	                
						--judge the side is wide enough to to pass in offset
						local sideIndex = neighborTri:GetNeighborWall(currNode);
						if(  sideIndex ~= -1 and neighborTri:GetSide(sideIndex):GetLength() >= offset ) then
						
							-- 4. 如果该相邻节点不在开放列表中,则将该节点添加到开放列表中, 
							--    并将该相邻节点的父节点设为当前节点,同时保存该相邻节点的G和F值;
							neighborTri:SetSessionID(pathSessionId);
							neighborTri:SetParentID(currNode:GetID());
							neighborTri:SetOpen(true);
							
							-- 计算启发值h
							neighborTri:CalcHeuristic(endPos);
							-- 计算三角形花费g
							neighborTri:SetGValue( currNode:GetGValue() + currNode:GetCost(neighborTri:GetID()) );
							
							--放入开放列表并排序
							openList[#openList + 1] = neighborTri;
                            if #openList >= 2 then
                                --按照HValue正序
    							table.sort(openList, function (x,y)
                                    local xFvalue = x:GetHValue() --[[+ x:GetGValue()]];
                                    local yFvalue = y:GetHValue() --[[+ y:GetGValue()]];
                                    return xFvalue < yFvalue; 
                                end);
                            end
							
							--保存穿入边
							neighborTri:SetArrivalWall(currNode:GetID());
						end
	                
	                else
	                
	                    -- 5. 如果该相邻节点在开放列表中, 
	                    --    则判断若经由当前节点到达该相邻节点的G值是否小于原来保存的G值,
	                    --    若小于,则将该相邻节点的父节点设为当前节点,并重新设置该相邻节点的G和F值
	                    if (neighborTri:GetOpen()) then
	                    
	                        if (neighborTri:GetGValue() + neighborTri:GetCost(currNode:GetID()) < currNode:GetGValue()) then
	                            currNode:SetGValue(neighborTri:GetGValue() + neighborTri:GetCost(currNode:GetID()));
	                            currNode:SetParentID(neighborTri:GetID());
	                            currNode:SetArrivalWall(neighborTri:GetID());
	                        end
	                    else
	                        neighborTri = nil;
	                    end
	                end
	            end     
            end
        end
    end

    if (#closeList ~= 0) then
        local path = closeList[#closeList];
        pathList[#pathList + 1] = path;
        while (path:GetParentID() ~= -1) do
            pathList[#pathList + 1] = self.m_lstTriangle[path:GetParentID()];
            path = self.m_lstTriangle[path:GetParentID()];
        end
    end

    if (not foundPath) then
        return PathResCode.NotFoundPath,startPos,endPos,pathList;
    else
        return PathResCode.Success,startPos,endPos,pathList;
    end    
end

--[[
	* 根据拐点计算法获得导航网格的下一个拐点
	* way:
	* triPathList:
	* endPos:
	* offSet:
	* returns:下一个拐点
]]	
function MobaNavSeeker:GetFurthestWayPoint(way, triPathList, endPos, offSet)

    local nextWay = nil;
    local currPnt = way:GetPoint();
    local currTri = way:GetTriangle();
    local lastTriA = currTri;
    local lastTriB = currTri;

    local startIndex = table.indexof(triPathList, currTri); 		--开始路点所在的网格索引
    local outSide = currTri:GetSide(currTri:GetOutWallIndex());		--路径线在网格中的穿出边?
    local lastPntA = outSide:GetStartPoint();
    local lastPntB = outSide:GetEndPoint();
    local lastLineA = MobaLine2D.new(currPnt, lastPntA);
    local lastLineB = MobaLine2D.new(currPnt, lastPntB);
    local testPntA, testPntB;

    for i = startIndex + 1, #triPathList do
        currTri = triPathList[i];
        outSide = currTri:GetSide(currTri:GetOutWallIndex());
        if (i == #triPathList) then
        
            testPntA = endPos;
            testPntB = endPos;
        
        else
        
            testPntA = outSide:GetStartPoint();
            testPntB = outSide:GetEndPoint();
        end

        if (not MobaNMath.PointIsEqual(lastPntA,testPntA)) then
        
            if (lastLineB:ClassifyPoint(testPntA) == PointSide.RIGHT_SIDE) then
            
                nextWay = MobaWayPoint.new(lastPntB, lastTriB);
                return nextWay;
            
            elseif (lastLineA:ClassifyPoint(testPntA) ~= PointSide.LEFT_SIDE) then
            
                lastPntA = testPntA;
                lastTriA = currTri;
                --重设直线
                lastLineA = MobaLine2D.new(lastLineA:GetStartPoint(), lastPntA);
            end
        end

        if (not MobaNMath.PointIsEqual(lastPntB,testPntB)) then
        
            if (lastLineA:ClassifyPoint(testPntB) == PointSide.LEFT_SIDE) then
            
                nextWay = MobaWayPoint.new(lastPntA, lastTriA);
                return nextWay;
            
            elseif (lastLineB:ClassifyPoint(testPntB) ~= PointSide.RIGHT_SIDE) then
            
                lastPntB = testPntB;
                lastTriB = currTri;
                --重设直线
                lastLineB = MobaLine2D.new(lastLineB:GetStartPoint(), lastPntB);
            end
        end
    end

    --到达终点
    nextWay = MobaWayPoint.new(endPos, triPathList[#triPathList]);

    return nextWay;
end

--[[
	* 生成最终的路径点
	* startPos:起始点
	* endPos:终点
	* triPathList:三角形路径列表
	* offSet:移动物体宽度
	* returns: tablr 路径点 
]]
function MobaNavSeeker:CreateWayPoints(startPos, endPos,triPathList,offSet)
    local wayPoints = {};

    if (#triPathList == 0 or startPos == nil or endPos == nil) then
        return PathResCode.Failed;
    end    

    -- 保证从起点到终点的顺序
    -- 倒置 triPathList
    local len = #triPathList;--长度
    local stp =  math.floor(len / 2);--步长
    local tmp = nil;
    for i=1,stp do
        --交换
        tmp = triPathList[i];
        triPathList[i] = triPathList[len - i + 1];
        triPathList[len - i + 1] = tmp;
    end

    -- 保存出边编号
    for i,tri in ipairs(triPathList) do

        if (i < #triPathList) then
        
            local nextTri = triPathList[i + 1];
            tri:SetOutWallIndex(tri:GetWallIndex(nextTri:GetID()));
        end
    end

    wayPoints[#wayPoints + 1] = startPos;

    --起点与终点在同一三角形中
    if (#triPathList == 1) then
    	wayPoints[#wayPoints + 1] = endPos;
        return PathResCode.Success,wayPoints;
    end

    local way = MobaWayPoint.new(startPos, triPathList[1]);
    local endFind = false;
    -- while ( (not MobaNMath.PointIsEqual(way:GetPoint(),endPos)) and #wayPoints <= #triPathList) do
    while ( (not MobaNMath.PointIsEqual(way:GetPoint(),endPos)) ) do
        -- print("--------------------->>>>",#wayPoints);
        -- print("--------------------->>>>way point",way:GetPoint().x,way:GetPoint().y);
        -- print("--------------------->>>>endPos",endPos.x,endPos.y);
        way = self:GetFurthestWayPoint(way, triPathList, endPos, offSet);
        if (way == nil) then
            return PathResCode.CanNotGetNextWayPoint;
        end

        -- 检测是否出现重复路径点，如果有就终止
        for i,wayPoint in pairs(wayPoints) do
            if MobaNMath.PointIsEqual(wayPoint,way:GetPoint()) then
                endFind = true;
                break;
            end
        end
        if endFind then break end;
        wayPoints[#wayPoints + 1] = way:GetPoint();
    end

    return PathResCode.Success,wayPoints;
end

--[[
	* 寻路
	* strPos: 起始位置
	* endPos: 终点位置
	* offset: 移动物体大小
	* returns1: 寻路结果
	* returns2: 输出路径点
]]
function MobaNavSeeker:Seek( startPos, endPos, offset)

    local path = {};

    if (self.m_lstTriangle == nil or #self.m_lstTriangle == 0) then
        return PathResCode.NoMeshData;
    end    

    self:ResetData();

    local pathTri = {};
    local res,startPos,endPos,pathTri = self:SeekTrianglePath(startPos,endPos,offset);
    if (res ~= PathResCode.Success) then
        return res;
    end

	--NavMonoEditor.m_lstTriPath = pathTri;
	res,path = self:CreateWayPoints(startPos, endPos, pathTri, offset);
    if (res ~= PathResCode.Success) then
        return res;
    end    

    return res,path;
end

return MobaNavSeeker;