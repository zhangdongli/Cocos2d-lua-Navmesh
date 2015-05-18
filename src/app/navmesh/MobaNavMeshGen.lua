--
-- Author: Zhang Dongli
-- Date: 2015-05-16 23:10:03
-- 这个类用来生成导航网格(保存，加载)，必须传入不可行走区域。

--[[
    * 生成结果
]]
NavResCode = {
    Success = 0,
    Failed = -1,
    NotFindDt = -2,
    FileNotExist = -3,
    VersionNotMatch = -4,
};

NAVMESH_VERSION = "SGNAVMESH_01";

MobaNavMeshGen = class("MobaNavMeshGen");

--------------------------------------------------
-- 获取对象
--------------------------------------------------

local s_cInstance = nil;
function MobaNavMeshGen.sInstance()
	if s_cInstance == nil then
		s_cInstance = MobaNavMeshGen.new();
	end
	return s_cInstance;
end

function MobaNavMeshGen:ctor()
	self.allEdges = {};  			--所有阻挡区域的边
    self.allPoints = {};			--所有顶点列表

	self.startEdge =nil				--开始边
    
	self.needSplitBig = false; 		--是否需要拆分大三角形
    self.needSplitSize = 50;		--拆分的尺寸
end

--------------------------------------------------
-- 属性
--------------------------------------------------

--[[
	* 是否需要拆分大三角形
]]
function MobaNavMeshGen:NeedSplitBig()
	return self.needSplitBig;
end

--[[
	* 设置是否需要拆分大三角形
]]
function MobaNavMeshGen:SetNeedSplitBig(value)
	self.needSplitBig = value;
end

--[[
	* 拆分的尺寸
]]
function MobaNavMeshGen:NeedSplitSize()
	return self.needSplitSize;
end

--[[
	* 设置拆分的尺寸
]]
function MobaNavMeshGen:SetNeedSplitSize(value)
	self.needSplitSize = value;
end

--------------------------------------------------
-- 文件读取
--------------------------------------------------

--[[
    * 写入文件
]]
function MobaNavMeshGen:WriteToFile(path,navTriangles)
    if path == nil then
        return NavResCode.Failed;
    end

    --生成序列化数据
    local resData = {};
    for i,tir in ipairs(navTriangles) do
        resData[#resData + 1] = tir:Write();
    end
    if resData == nil or table.nums(resData) == 0 then
        return NavResCode.Failed;
    end

    --转化为json
    local jsonStr = json.encode(resData);
    if jsonStr == nil then
        return NavResCode.Failed;
    end

    local f = assert(io.open(path, 'w'))
    f:write(jsonStr)
    f:close()

    return NavResCode.Success;
end

--[[
    * 从文件中读取
    * return1:读取结果
    * return2:读取结果
]]
function MobaNavMeshGen:ReadFormFile(path)
    local triAll = {};
    if path == nil then
        return NavResCode.Failed,triAll;
    end

    -- 从文件读取
    local f = assert(io.open(path, 'r'));
    local string = f:read("*all");
    f:close();
    if string == nil then
        return NavResCode.Failed,triAll;
    end 

    -- json 序列化
    local data = json.decode(string);
    if data == nil or table.nums(data) == 0 then
        return NavResCode.Failed,triAll;
    end

    -- 解析json
    for i,triData in ipairs(data) do
        local tri = MobaTriangle.new();
        tri:Read(triData);
        triAll[#triAll + 1] = tri;
    end

    return NavResCode.Success,triAll;

end

--------------------------------------------------
-- 函数
--------------------------------------------------

--[[
	* 保存用到的顶点
	* points: 保存的点集合
]]
function MobaNavMeshGen:AddPoint(points)

	for i,point in ipairs(points) do
		table.insert(self.allPoints,point);
	end

    return NavResCode.Success;
end

--[[
	* 保存所有边
	* points: 保存的点集合
]]	
function MobaNavMeshGen:AddEdge(points)

    local pBegin = points[1];
    for i=2,#points do
    	local pEnd = points[i];
        local line = MobaLine2D.new(pBegin, pEnd);
        table.insert(self.allEdges,line);
        pBegin = pEnd;
    end
    local lineEnd = MobaLine2D.new(pBegin, points[1]);
    table.insert(self.allEdges,lineEnd);

    return NavResCode.Success;
end

--[[
	* 初始化创建导航网格需要的数据
	* polyAll:所有阻挡区域
	* returns1:  NavResCode 初始化结果
	* returns2:  polyAll  初始化完的多边形集合
]]
function MobaNavMeshGen:InitData(polyAll)

    self.allEdges =  {};
    self.allPoints = {};

    local resCode,newPolyAll = MobaNavUtil.UnionAllPolygon(polyAll);
    if (resCode ~= PolyResCode.Success) then
        return NavResCode.Failed;
    end    
    -- 保存所有点和边
    for i,poly in ipairs(newPolyAll) do
    	local points = poly:GetPoints();
    	if (#points >= 3) then
        	self:AddPoint(points);
        	self:AddEdge(points);
        end
    end

	if(newPolyAll ~= nil and #newPolyAll > 0) then
		self.startEdge = MobaLine2D.new(newPolyAll[1]:GetPoints()[1], newPolyAll[1]:GetPoints()[2]);
	end		
    return NavResCode.Success,newPolyAll;
end

--[[
	* 判断这条线段是否没有和其他的边相交
	* sPnt:
	* point:
	* returns:
]]
function MobaNavMeshGen:IsVisibleIn2Point( sPnt,  ePnt)

    local line = MobaLine2D.new(sPnt, ePnt);
    local isIns,interPos = false,nil;
    for i,edge in ipairs(self.allEdges) do
    	isIns,interPos = edge:Intersection(line);
    	if (isIns == LineCrossState.CROSS) then
        
            if ( (not MobaNMath.PointIsEqualZero(cc.pSub(sPnt , interPos))) and (not MobaNMath.PointIsEqualZero(cc.pSub(ePnt , interPos)))  ) then
                return false;
            end    
        end
    end

    return true;
end

--[[
	* 判断点是否是线段的可见点，组成的三角形没有和其他边相交
	* line: 线段
	* point: 点
	* returns: 是否是线段的可见点
]]
function MobaNavMeshGen:IsPointVisibleOfLine( line,  point)

    if (line == nil) then return false end;


    local sPnt = line:GetStartPoint();
    local ePnt = line:GetEndPoint();

    -- 是否是线段端点
    if (MobaNMath.PointIsEqual(point,sPnt) or MobaNMath.PointIsEqual(point,ePnt)) then
        return false;
    end
        
    --点不在线段的右侧（多边形顶点顺序为顺时针）
    if (line:ClassifyPoint(point) ~= PointSide.RIGHT_SIDE) then
        return false;
    end    

    if (not self:IsVisibleIn2Point(sPnt, point)) then
        return false;
    end    

    if (not self:IsVisibleIn2Point(ePnt, point)) then
        return false;
    end    

    return true;
end

--[[
	* 找到指定边的约束边DT
	* line: 要找的线
	* return1 : 是否找到
	* return2 : 找到的dt点
]]	
function MobaNavMeshGen:FindDT(line)

    local dtPoint = cc.p(0,0);
    if (line == nil) then
        return false,dtPoint;
    end    

    local ptA = line:GetStartPoint();
    local ptB = line:GetEndPoint();

    local visiblePnts = {};
    for i,point in ipairs(self.allPoints) do
    	if (self:IsPointVisibleOfLine(line, point)) then
    		table.insert(visiblePnts,point);
        end    
    end

    if (#visiblePnts == 0) then
        return false;
    end    

    local bNotContinue = true;
    dtPoint = visiblePnts[1];

    repeat
    
        bNotContinue = true;
        --Step1.构造三角形的外接圆，以及外接圆的包围盒
        local circle = MobaNMath.CreateCircle(ptA, ptB, dtPoint);
        local boundBox = MobaNMath.GetCircleBoundBox(circle);

        --Step2. 依次访问网格包围盒内的每个网格单元：
        --若某个网格单元中存在可见点 p, 并且 ∠p1pp2 > ∠p1p3p2，则令 p3=p，转Step1；
        --否则，转Step3.
        local angOld = math.abs(MobaNMath.LineRadian(ptA, dtPoint, ptB));
        for i,pnt in ipairs(visiblePnts) do
            if not ( MobaNMath.PointIsEqual(pnt, ptA) or MobaNMath.PointIsEqual(pnt , ptB) or MobaNMath.PointIsEqual(pnt , dtPoint) ) then
	            
	            if (boundBox:Contains(pnt)) then

		            local angNew = math.abs(MobaNMath.LineRadian(ptA, pnt, ptB));
		            if (angNew > angOld) then
		                dtPoint = pnt;
		                bNotContinue = false;
		                break;
		            end
	        	end

        	end
        end
           --true 转Step3
    until (bNotContinue);

    --Step3. 若当前网格包围盒内所有网格单元都已被处理完，
    -- 也即C（p1，p2，p3）内无可见点，则 p3 为的 p1p2 的 DT 点
    return true,dtPoint;
end

--[[
	*创建导航网格
	*zhangAiPolyAll:所有阻挡区域
	*returns1: NavResCode 生成结果
	*rerurns2: table 输出的导航网格
]]
function MobaNavMeshGen:CreateNavMesh(zhangAiPolyAll ,id , groupid)

    local polyAll = clone(zhangAiPolyAll);

    local triAll = {};    --结果集合
    local allLines = {};  --线段堆栈

    --Step1 保存顶点和边
    local initRes,polyAll = self:InitData(polyAll);
    if (initRes ~= NavResCode.Success) then
        return initRes,triAll;
    end

    local lastNeighborId = -1;
    local lastTri = nil;

    --Step2.遍历边界边作为起点
    do
		local sEdge = self.startEdge;
		allLines[#allLines + 1] = sEdge;
        local edge = nil;

        repeat
            --Step3.选出计算出边的DT点，构成约束Delaunay三角形
            edge = allLines[#allLines];
            table.remove(allLines,#allLines);

            local isFindDt,dtPoint = self:FindDT(edge);
            if (isFindDt) then
	            local lAD = MobaLine2D.new(edge:GetStartPoint(), dtPoint);
	            local lDB = MobaLine2D.new(dtPoint, edge:GetEndPoint());

	            --创建三角形
				local delaunayTri = MobaTriangle.getTriangleByParams(edge:GetStartPoint(), edge:GetEndPoint(), dtPoint, id, groupid);
				id = id + 1;

	            -- 保存邻居节点
	            table.insert(triAll, delaunayTri);

	            -- 保存上一次的id和三角形
	            lastNeighborId = delaunayTri:GetID();
	            lastTri = delaunayTri;

	            local inLine = false;
	            local lineIndex = -1;
	            --Step4.检测刚创建的的线段ad,db；如果如果它们不是约束边
	            --并且在线段堆栈中，则将其删除，如果不在其中，那么将其放入
	            inLine,lineIndex = MobaLine2D.CheckLineIn(self.allEdges,lAD);
	            if (not inLine) then
	            	
	            	inLine,lineIndex = MobaLine2D.CheckLineIn(allLines,lAD);
	                if (not inLine) then
	                    table.insert(allLines, lAD);
	                else
	                	table.remove(allLines,lineIndex);
	                end    
	            end

	            inLine,lineIndex = MobaLine2D.CheckLineIn(self.allEdges,lDB);
	            if (not inLine) then
	            	
	            	inLine,lineIndex = MobaLine2D.CheckLineIn(allLines,lDB);
	                if (not inLine) then
	                    table.insert(allLines, lDB);
	                else
	                	table.remove(allLines,lineIndex);
	                end    
	            end
        	end

            --Step5.如果堆栈不为空，则转到第Step3.否则结束循环 
        until (#allLines <= 0);
    end

    -- 计算邻接边
    for i,tri in ipairs(triAll) do
        -- 计算邻居边
        for j,triNext in ipairs(triAll) do
            if (tri:GetID() ~= triNext:GetID()) then
	            local result = tri:isNeighbor(triNext);
	            if (result ~= -1) then
	                tri:SetNeighbor(result , triNext:GetID() );
	            end
        	end
        end
    end
    return NavResCode.Success,triAll;
end


return MobaNavMeshGen;