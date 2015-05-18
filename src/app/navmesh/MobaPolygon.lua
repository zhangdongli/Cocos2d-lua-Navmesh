-- Author: zhang dongli
-- Date: 2015-5-9
-- Navigation Mesh 多边形

MobaPolygon = class("MobaPolygon");

PolyResCode = {
    Success = 0,
    ErrEmpty = -1,      --空多边形
    ErrNotCross = -2,   --没有相交
    ErrCrossNum = -3,   --多边形交点数量错误
    ErrNotInside = -4   --不在多边形上
};

function MobaPolygon.Polygon(points)
	local obj = MobaPolygon.new();
	obj:SetPoints(points);
	return obj;
end

function MobaPolygon:ctor()
	self.m_iTag = 0; 		--标志
    self.m_lstPoints = {};  --列表点
end

----------------------------------------------------
-- 属性
----------------------------------------------------

--[[
	* 获取标识
]]
function MobaPolygon:GetTag()
    return self.m_iTag;
end

--[[
	* 设置标签
]]
function MobaPolygon:SetTag(tag)
    self.m_iTag = tag;
end

--[[
	* 获取顶点列表
]]
function MobaPolygon:GetPoints()
	return self.m_lstPoints;
end

--[[
	* 设置顶点列表
]]
function MobaPolygon:SetPoints(points)
	self.m_lstPoints = points;
end

--[[
	* 添加顶点到顶点列表
]]
function MobaPolygon:AddPoints(point)
	self.m_lstPoints[#self.m_lstPoints + 1] = point;

end

----------------------------------------------------
-- 函数
----------------------------------------------------

--[[
    *删除重复顶点
]]
function MobaPolygon:DelRepeatPoint()
    local i,j,max = 1,0,#self.m_lstPoints;
    while i <= max do
        j = i + 1;--从i指向的下一个开始比较
        while j <= max do
            -- 如果这2个点相同
            if (MobaNMath.PointIsEqual(self.m_lstPoints[i],self.m_lstPoints[j])) then
                table.remove(self.m_lstPoints, j);--移除相同点
                j = i; --内循环下标指向i,意思是回退一个，因为j初始等于i+1。
                i = i - 1;--外层循环下标回退一个。
                if i < 1 then i = 1 end;--防止下标小于等于0。
                max = max - 1;--总个数减1。
                if max < 0 then max = 0 end;--防止小于0。
            end
            j = j + 1;--内循环指向下一个。
        end
        i = i + 1;--外循环指向下一个。
    end
end

--[[
    * 顺时针排序
]]
function MobaPolygon:CW()
    if (not self:IsCW()) then
        -- 倒置 m_lstPoints
        local len = #self.m_lstPoints;--长度
        local stp = checkint(len / 2);--步长
        local tmp = nil;
        for i=1,stp do
            --交换
            tmp = self.m_lstPoints[i];
            self.m_lstPoints[i] = self.m_lstPoints[len - i + 1];
            self.m_lstPoints[len - i + 1] = tmp;
        end
    end
end


--[[
    * 判断是否是顺时针
]]
function MobaPolygon:IsCW()

    if (#self.m_lstPoints <= 2) then
        return false;
    end

    --最下（y最小）最左（x最小）点， 肯定是一个凸点
    --寻找最下点
    local topPoint = self.m_lstPoints[1];
    local topIndex = 0;
    for i,currPoint in ipairs(self.m_lstPoints) do
        if ((topPoint.y > currPoint.y) or ((topPoint.y == currPoint.y) and (topPoint.x > currPoint.x))) then
            topPoint = currPoint;
            topIndex = i;
        end
    end

    --寻找左右邻居
    local preIndex = 1;
    if (topIndex - 1) >= 1 then
        preIndex = topIndex - 1;
    else
        preIndex = #self.m_lstPoints;     
    end

    local nextIndex = 1;
    if (topIndex + 1) <= #self.m_lstPoints then
        nextIndex = topIndex + 1;
    else
        nextIndex = 1;
    end    

    local prePoint = self.m_lstPoints[preIndex];
    local nextPoint = self.m_lstPoints[nextIndex];

    --三点共线情况不存在，若三点共线则说明必有一点的y（斜线）或x（水平线）小于topPt
    local r = MobaNMath.CrossProduct(cc.pSub(prePoint,topPoint), cc.pSub(nextPoint,topPoint));
    if (r > 0) then
        return true;
    end    

    return false;
end


--[[
	*  返回多边形包围盒
]]
function MobaPolygon:GetCoverRect()
    local rect = MobaRect.rect(0, 0, 0, 0);
    local count =  #self.m_lstPoints;
    for i = 1, count do
        if (rect.xMin > self.m_lstPoints[i].x) then
            rect.xMin = self.m_lstPoints[i].x;
        end
            
        if (rect.xMax < self.m_lstPoints[i].x) then
            rect.xMax = self.m_lstPoints[i].x;
        end
            
        if (rect.yMin > self.m_lstPoints[i].y) then
            rect.yMin = self.m_lstPoints[i].y;
        end   

        if (rect.yMax < self.m_lstPoints[i].y) then
            rect.yMax = self.m_lstPoints[i].y;
        end
    end
    return rect;
end

--[[
	* 合并两个交叉的多边形(多边形必须先转换为顺时针方向，调用CW()函数!)
	* other Polygon 另一个多边形
	* returns1 PolyResCode  合并结果
	* returns2 polyRes 	合并后的多边形集合	
]]
function MobaPolygon:Union(other)

    local linkRes = nil; --合并结果
	local polyRes = {};  --合并后的多边形集合

    -- 如果有一个多边形的定点列表为空
    if (#self.m_lstPoints == 0 or #other.m_lstPoints == 0) then
        return PolyResCode.ErrEmpty,polyRes;
    --如果2个多边形的包围盒不相交     
    elseif (not MobaNMath.CheckCrossByRect(self:GetCoverRect(), other:GetCoverRect())) then
        return PolyResCode.ErrNotCross,polyRes;
    end    

    local mainNode = {};     --主多边形顶点集合
    local subNode = {};      --需要合并的多边形顶点集合

    -- 初始化主多边形顶点集合
    local selfCount = #self.m_lstPoints;
    for i = 1, selfCount do
        local currNode = MobaNavNode.node(self.m_lstPoints[i], false, true);
        if (i > 1) then
        
            local preNode = mainNode[i - 1];
            preNode.next = currNode;
        end
        mainNode[#mainNode + 1] = currNode;
    end

    -- 初始化需要合并的多边形顶点集合
    local otherCount = #other.m_lstPoints;
    for  j = 1, otherCount do
        local currNode = MobaNavNode.node(other.m_lstPoints[j], false, false);
        if (j > 1) then
        
            local preNode = subNode[j - 1];
            preNode.next = currNode;
        end
        subNode[#subNode + 1] = currNode;
    end

    -- 合并两个节点列表，生成交点，并按顺时针序插入到顶点表中
    local result,insCnt = MobaNavUtil.NavNodeIntersectPoint(mainNode, subNode);
    if (result == PolyResCode.Success and insCnt > 0) then
        
        --如果交点个数为基数个,发生了错误。
        --因为凸多边形如果相交，交点必为偶数个。
        if (insCnt % 2 ~= 0) then
            return PolyResCode.ErrCrossNum,polyRes;
        else
            -- 合并两个节点列表为一个多边形，结果为顺时针序(生成的内部孔洞多边形为逆时针序)
            linkRes,polyRes = MobaNavUtil.LinkToPolygon(mainNode, subNode);
            return linkRes,polyRes;
        end
    end

    return PolyResCode.ErrCrossNum,polyRes;
end

return MobaPolygon;