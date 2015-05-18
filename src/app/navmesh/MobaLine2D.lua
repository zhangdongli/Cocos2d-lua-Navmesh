--
-- Author: zhang dongli
-- Date: 2015-5-9
-- Navigation Mesh 线


--[[
	* 点与线段所在位置
]]
PointSide = {
    ON_LINE = 0,     --在线段上
    LEFT_SIDE = 1,   --在线段左边
    RIGHT_SIDE = 2,  --在线段右边
};

--[[
	* 两线段交叉状态
]]
LineCrossState = {
    COLINE = 0,     --外线口
    PARALLEL = 1,   	--平行线
    CROSS = 2,      	--相交
    NOT_CROSS = 3   	--无相交
};

MobaLine2D = class("MobaLine2D");

function MobaLine2D:ctor(ps,pe)
	self.m_cStartPoint = ps;  --起始点
	self.m_cEndPoint = pe;    --结束点
end

--[[
	* 获取起始点
	* returns 起始点
]]
function MobaLine2D:GetStartPoint()
    return self.m_cStartPoint;
end

--[[
	* 获取结束点
	* returns 结束点
]]
function MobaLine2D:GetEndPoint()
    return self.m_cEndPoint;
end

--[[
	*检测线段是否在给定线段列表里面
    *allLines:线段列表
    *chkLine:检查线段
    * 返回值1: bool 
    * 返回值2: int
]]
function MobaLine2D.CheckLineIn(allLines,chkLine)
    local index = -1;
    local count = table.nums(allLines);
    for i = 1,count do
    	local line = allLines[i];
        if (line:Equals(chkLine)) then
            index = i;
            return true,index;
        end
    end
    return false,index;
end

--[[
	* 判断点与直线的关系，假设你站在a点朝向b点， 
	* 则输入点与直线的关系分为：Left, Right or Centered on the line
	* point : 判断点
	* returns : PointSide  判断结果
]]	
function MobaLine2D:ClassifyPoint(point)
	if MobaNMath.PointIsEqual(point,self.m_cStartPoint) or MobaNMath.PointIsEqual(point,self.m_cEndPoint) then
        return PointSide.ON_LINE;
    end

    --向量a
    local vectorA = cc.pSub(self.m_cEndPoint,self.m_cStartPoint);
    
    --向量b
    local vectorB = cc.pSub(point,self.m_cStartPoint);

    local crossResult =MobaNMath.CrossProduct(vectorA, vectorB);
    if (MobaNMath.NumberIsEqualZero(crossResult)) then
        return PointSide.ON_LINE;
    elseif (crossResult < 0) then
        return PointSide.RIGHT_SIDE;
    else
        return PointSide.LEFT_SIDE;
    end
end

--[[
	* 计算两条二维线段的交点
    * other: Other line
    * returns1: LineCrossState 返回值说明了两条线段的位置关系(COLINE,PARALLEL,CROSS,NOT_CROSS)
    * returns2: Point 输出的线段交点
]]    
function MobaLine2D:Intersection(other)
	local intersectPoint = cc.p(-1,-1); -- 交点
    if (not MobaNMath.CheckCrossByPoints(self.m_cStartPoint, self.m_cEndPoint, other.m_cStartPoint, other.m_cEndPoint)) then
        return LineCrossState.NOT_CROSS,nil;--不相交
    end

    local A1, B1, C1, A2, B2, C2;

    A1 = self.m_cEndPoint.y - self.m_cStartPoint.y;
    B1 = self.m_cStartPoint.x - self.m_cEndPoint.x;
    C1 = self.m_cEndPoint.x * self.m_cStartPoint.y - self.m_cStartPoint.x * self.m_cEndPoint.y;

    A2 = other.m_cEndPoint.y - other.m_cStartPoint.y;
    B2 = other.m_cStartPoint.x - other.m_cEndPoint.x;
    C2 = other.m_cEndPoint.x * other.m_cStartPoint.y - other.m_cStartPoint.x * other.m_cEndPoint.y;

    if (MobaNMath.NumberIsEqualZero(A1 * B2 - B1 * A2)) then
        if (MobaNMath.NumberIsEqualZero((A1 + B1) * C2 - (A2 + B2) * C1)) then
            return LineCrossState.COLINE,nil;--外线口
        else
            return LineCrossState.PARALLEL,nil;--平行
        end
    else
    
        intersectPoint.x = ((B2 * C1 - B1 * C2) / (A2 * B1 - A1 * B2));
        intersectPoint.y = ((A1 * C2 - A2 * C1) / (A2 * B1 - A1 * B2));
        return LineCrossState.CROSS,intersectPoint;--相交
    end
end

--[[
	* 获得直线方向
	* returns 矢量
]]
function MobaLine2D:GetDirection()
    local dir = cc.pSub(self.m_cEndPoint,self.m_cStartPoint);
    return dir;
end

--[[
	* 线段长度
	* returns 长度
]]
function MobaLine2D:GetLength()
    return math.sqrt(math.pow(self.m_cStartPoint.x - self.m_cEndPoint.x, 2.0) + math.pow(self.m_cStartPoint.y - self.m_cEndPoint.y, 2.0));
end

--[[
	* 两条线段是否相等
    * line:判断对象
    * returns bool 是否相等
]]
function MobaLine2D:Equals(line)
	--只是一个点
	if MobaNMath.PointIsEqualZero(cc.pSub(line.m_cStartPoint,line.m_cEndPoint)) or
	   MobaNMath.PointIsEqualZero(cc.pSub(self.m_cStartPoint,self.m_cEndPoint)) then
		return false;
	end	

	--whatever the direction
	local bEquals = false;
	if MobaNMath.PointIsEqualZero(cc.pSub(self.m_cStartPoint,line.m_cStartPoint)) then
		bEquals = true;
	else
		bEquals = MobaNMath.PointIsEqualZero(cc.pSub(self.m_cStartPoint,line.m_cEndPoint)); 	
	end
	
	if (bEquals) then
		if MobaNMath.PointIsEqualZero(cc.pSub(self.m_cEndPoint,line.m_cStartPoint)) then
			bEquals = true;
		else
			bEquals = MobaNMath.PointIsEqualZero(cc.pSub(self.m_cEndPoint,line.m_cEndPoint));
		end	
	end
	return bEquals;
end

return MobaLine2D;