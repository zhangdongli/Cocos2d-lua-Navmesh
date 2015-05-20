-- Author: zhang dongli
-- Date: 2015-5-9
-- Navigation Mesh 三角形

MobaTriangle = class("MobaTriangle");

--写入读取文件 key
ZDL_TRI_VECPOINTS = "VecPoints";
ZDL_TRI_ID = "Id";
ZDL_TRI_GROUPID = "GroupID";
ZDL_TRI_VECNEIGHBORS = "VecNeighbors";
ZDL_TRI_CENTER = "Center";
ZDL_TRI_VECWALLDISTANCE = "VecWallDistance";


--[[
    * 获取三角形
]]
function MobaTriangle.getTriangle()
    return MobaTriangle.new();
end

--[[
    * 获取三角形
]]
function MobaTriangle.getTriangleByParams( pos1,  pos2 ,  pos3 ,  id ,  groupid )
    local obj =  MobaTriangle.new();
    
    obj.m_iID = id;
    obj.m_iGroupID = groupid;

    obj.m_vecPoints[#obj.m_vecPoints + 1] = pos1;
    obj.m_vecPoints[#obj.m_vecPoints + 1] = pos2;
    obj.m_vecPoints[#obj.m_vecPoints + 1] = pos3;

    --计算中心点
    local temp = cc.p(0,0);
    temp.x = (obj.m_vecPoints[1].x + obj.m_vecPoints[2].x + obj.m_vecPoints[3].x) / 3;
    temp.y = (obj.m_vecPoints[1].y + obj.m_vecPoints[2].y + obj.m_vecPoints[3].y) / 3;
    obj.m_cCenter = temp;

    --计算三角形相邻两边的中点距离
    local wallMidPoint = {};
    wallMidPoint[1] = cc.p((obj.m_vecPoints[1].x + obj.m_vecPoints[2].x) / 2, (obj.m_vecPoints[1].y + obj.m_vecPoints[2].y) / 2);
    wallMidPoint[2] = cc.p((obj.m_vecPoints[2].x + obj.m_vecPoints[3].x) / 2, (obj.m_vecPoints[2].y + obj.m_vecPoints[3].y) / 2);
    wallMidPoint[3] = cc.p((obj.m_vecPoints[3].x + obj.m_vecPoints[1].x) / 2, (obj.m_vecPoints[3].y + obj.m_vecPoints[1].y) / 2);

    obj.m_vecWallDistance[1] =  math.sqrt((wallMidPoint[1].x - wallMidPoint[2].x) * (wallMidPoint[1].x - wallMidPoint[2].x)
        + (wallMidPoint[1].y - wallMidPoint[2].y) * (wallMidPoint[1].y - wallMidPoint[2].y));
    obj.m_vecWallDistance[2] =  math.sqrt((wallMidPoint[2].x - wallMidPoint[3].x) * (wallMidPoint[2].x - wallMidPoint[3].x)
        + (wallMidPoint[2].y - wallMidPoint[3].y) * (wallMidPoint[2].y - wallMidPoint[3].y));
    obj.m_vecWallDistance[3] = math.sqrt((wallMidPoint[3].x - wallMidPoint[1].x) * (wallMidPoint[3].x - wallMidPoint[1].x)
        + (wallMidPoint[3].y - wallMidPoint[1].y) * (wallMidPoint[3].y - wallMidPoint[1].y));

    --计算包围盒
    obj:CalcCollider();

    return obj;
end

function MobaTriangle:ctor()
	--基础数据
	self.m_vecPoints = {};  	--三角形定点列表
	self.m_iID = -1;  						                --三角形ID
	self.m_iGroupID = -1;   			            	    --三角形组ID
	self.m_vecNeighbors = {-1,-1,-1};   	                --三角形邻居节点ID
    
    --计算数据
    self.m_cCenter = cc.p(0,0);  				--三角形中心点
    self.m_cBoxCollider = MobaRect.new();  	    --三角形包围盒
    self.m_vecWallDistance = {};  				--三角形相邻两边的中点距离
end

--[[
    * 克隆一个Nva三角形
    * 返回 MobaNavTriangle 三角形
]]
function MobaTriangle:CloneNavTriangle()

    local tri =  MobaNavTriangle.new();
    --基础数据
    tri.m_vecPoints = clone(self.m_vecPoints);
    -- copyTable(self.m_vecPoints,tri.m_vecPoints);         --三角形定点列表
    tri.m_iID = self.m_iID;                              --三角形ID
    tri.m_iGroupID = self.m_iGroupID;                    --三角形组ID
    tri.m_vecNeighbors = clone(self.m_vecNeighbors);
    -- copyTable(self.m_vecNeighbors,tri.m_vecNeighbors);   --三角形邻居节点ID
    
    --计算数据
    tri.m_cCenter = clone(self.m_cCenter)
    -- copyTable(self.m_cCenter,tri.m_cCenter);                --三角形中心点

    tri.m_cBoxCollider = clone(self.m_cBoxCollider)
    -- copyTable(self.m_cBoxCollider,tri.m_cBoxCollider);      --三角形包围盒

    tri.m_vecWallDistance = clone(self.m_vecWallDistance);
    -- copyTable(self.m_vecWallDistance,tri.m_vecWallDistance);--三角形相邻两边的中点距离
    return tri;
end

--[[
    * 计算包围盒
]]
function MobaTriangle:CalcCollider()

    --计算包围盒
    if MobaNMath.PointIsEqual(self.m_vecPoints[1],self.m_vecPoints[2]) 
        or MobaNMath.PointIsEqual(self.m_vecPoints[2],self.m_vecPoints[3]) 
        or MobaNMath.PointIsEqual(self.m_vecPoints[1],self.m_vecPoints[3]) then
        print("MobaTriangle:这不是一个三角形");
        return;
    end

    local collider = MobaRect.new();
    collider.xMin = self.m_vecPoints[1].x;
    collider.xMax = self.m_vecPoints[1].x;
    collider.yMin = self.m_vecPoints[1].y;
    collider.yMax = self.m_vecPoints[1].y;

    for i=1,3 do
        if (self.m_vecPoints[i].x < collider.xMin) then
        
            collider.xMin = self.m_vecPoints[i].x;

        elseif (self.m_vecPoints[i].x > collider.xMax) then
        
            collider.xMax = self.m_vecPoints[i].x;

        end

        if (self.m_vecPoints[i].y < collider.yMin) then
        
            collider.yMin = self.m_vecPoints[i].y;
        
        elseif (self.m_vecPoints[i].y > collider.yMax) then
        
            collider.yMax = self.m_vecPoints[i].y;

        end
    end

    self.m_cBoxCollider = collider;    
end

--[[
    * 计算邻居节点
    * triNext: 一个三角形
    * returns:返回相邻点的下标
]]
function MobaTriangle:isNeighbor(triNext)
    for i=1,3 do
        for j=1,3 do
            if (self:GetSide(i):Equals(triNext:GetSide(j))) then
                return i;
            end
        end
    end
    return -1;
end


--[[
    *  根据索引获得相应的边
    * sideIndex int 边的索引
    * returns MobaLine2D 边
]]
function MobaTriangle:GetSide(sideIndex)
    local newSide;
    if 1 == sideIndex then
        newSide = MobaLine2D.new(self.m_vecPoints[1], self.m_vecPoints[2]);
    elseif 2 == sideIndex then
        newSide = MobaLine2D.new(self.m_vecPoints[2], self.m_vecPoints[3]);
    elseif 3 == sideIndex then
        newSide = MobaLine2D.new(self.m_vecPoints[3], self.m_vecPoints[1]);
    else
        newSide = MobaLine2D.new(self.m_vecPoints[1], self.m_vecPoints[2]);
    end

    return newSide;
end

--[[
    * 测试给定点是否在三角形中
    * 点在三角形边上也算
    * pt point 要判断的点
    * returns bool 是否在三角形中
]]
function MobaTriangle:IsPointIn(pt)

    if (self.m_cBoxCollider.xMin ~= self.m_cBoxCollider.xMax and (not self.m_cBoxCollider:Contains(pt))) then
        return false;
    end    

    local resultA = self:GetSide(1):ClassifyPoint(pt);
    local resultB = self:GetSide(3):ClassifyPoint(pt);
    local resultC = self:GetSide(3):ClassifyPoint(pt);

    if (resultA == PointSide.ON_LINE or resultB == PointSide.ON_LINE or resultC == PointSide.ON_LINE) then
        return true;
    elseif (resultA == PointSide.RIGHT_SIDE and resultB == PointSide.RIGHT_SIDE and resultC == PointSide.RIGHT_SIDE) then
        return true;
    end

    return false;
end

--[[
    * 获得邻居ID边的索引
    * neighborID int 邻居三角形ID
    * return int index
]]
function MobaTriangle:GetWallIndex(neighborID)
    for i=1,3 do
        if (self.m_vecNeighbors[i] ~= -1 and self.m_vecNeighbors[i] == neighborID) then
            return i;
        end
    end
    return -1;
end

--[[
    * 比较并获取三角形邻居边索引
    * triNext Triangle 三角形
    * returns int 邻边索引
]]
function MobaTriangle:GetNeighborWall(triNext)
    for i=1,3 do
        for j=1,3 do
            if (self:GetSide(i):Equals(triNext:GetSide(j))) then
                return i;
            end
        end
    end

    return -1;
end

--[[
    * 获取三角形ID
]]
function MobaTriangle:GetID()
    return self.m_iID;
end

--[[
    * 获取组ID
]]
function MobaTriangle:GetGroupID()
    return self.m_iGroupID;
end

--[[
    * 获取中心点
]]
function MobaTriangle:GetCenter()
    return self.m_cCenter;
end

--[[
    * 获取包围盒
]]
function MobaTriangle:GetBoxCollider()
    return self.m_cBoxCollider;
end

--[[
    * 获取指定点
]]
function MobaTriangle:GetPoint(index)

    if (index > 3) then
        printError("GetPoint:index 不能大于3.");
        return cc.p(0,0);
    end

    return self.m_vecPoints[index];
end

--[[
    * 获取邻居节点ID
]]
function MobaTriangle:GetNeighbor(index)

    if (index > 3) then
    
        printError("GetNeighbor:index 不能大于3.");
        return -1;
    end

    return self.m_vecNeighbors[index];
end

--[[
    * 设置邻居三角形ID
    * index int 边索引
    * id int 邻居三角形ID
]]
function MobaTriangle:SetNeighbor(index,id)

    if (index > 3) then
    
        printError("SetNeighbor:index 不能大于3.");
        return;
    end

    self.m_vecNeighbors[index] = id;
end


--[[
    * 获取三边中点距离
]]
function MobaTriangle:GetWallDis(index)

    if (index > 3) then
    
        printError("GetWallDis:index 不能大于3.");
        return -1;
    end

    return this.m_vecWallDistance[index];
end

--[[
    * 读取数据
]]
function MobaTriangle:Read(binReader)
    
    -- 读取id
    self.m_iID = binReader[ZDL_TRI_ID];
    -- 读取多边形的顶点
    for i,pD in ipairs(binReader[ZDL_TRI_VECPOINTS]) do
        self.m_vecPoints[i] = cc.p(pD["x"],pD["y"]);
    end

    -- 计算包围盒
    self:CalcCollider();

    -- 读取邻居节点
    for i,nD in ipairs(binReader[ZDL_TRI_VECNEIGHBORS]) do
        self.m_vecNeighbors[i] = nD;
    end

    -- 读取每条边中点距离
    for i,wallD in ipairs(binReader[ZDL_TRI_VECWALLDISTANCE]) do
        self.m_vecWallDistance[i] = wallD;
    end

    -- 读取中心点
    local tempCenter = self.m_cCenter;
    tempCenter.x = binReader[ZDL_TRI_CENTER]["x"];
    tempCenter.y = binReader[ZDL_TRI_CENTER]["y"];
    self.m_cCenter = tempCenter;

    -- 读取区域id
    self.m_iGroupID = binReader[ZDL_TRI_GROUPID];
end

--[[
    * 写入数据
]]
function MobaTriangle:Write()
    return {
        [ZDL_TRI_VECPOINTS] = self.m_vecPoints,
        [ZDL_TRI_ID] = self.m_iID,
        [ZDL_TRI_GROUPID] = self.m_iGroupID,
        [ZDL_TRI_VECNEIGHBORS] = self.m_vecNeighbors,
        [ZDL_TRI_CENTER] = self.m_cCenter,
        [ZDL_TRI_VECWALLDISTANCE] = self.m_vecWallDistance
    };
end

return MobaTriangle;