--
-- Author: zhang dongli
-- Date: 2015-5-9
-- Navigation Mesh 专用数学类

MobaNMath = class("MobaNMath");

EPSILON = 1e-005;  --最小常量

--[[
    *返回顶角在o点，起始边为os，终止边为oe的夹角, 即∠soe (单位：弧度) 
    *矢量os 在矢量 oe的顺时针方向,返回正值;否则返回负值 
    * s:点
    * o:点
    * e:点
    * returns:返回弧度
]]
function MobaNMath.LineRadian( s,  o,  e)

    local dx12 = s.x - o.x;
    local dy12 = s.y - o.y;
    local dx32 = e.x - o.x;
    local dy32 = e.y - o.y;

    --角度计算公式s→ * e→ = |s|*|e|*cosθ

    local cosfi = dx12 * dx32 + dy12 * dy32;

    local norm = (dx12 * dx12 + dy12 * dy12) * (dx32 * dx32 + dy32 * dy32);

    cosfi = cosfi / math.sqrt(norm);

    if (cosfi >= 1.0) then return 0 end
    if (cosfi <= -1.0) then return -math.pi end

    local angleRadian = math.acos(cosfi);

    -- 说明矢量os 在矢量 oe的顺时针方向 
    if (dx12 * dy32 - dy12 * dx32 > 0) then
        return angleRadian;
    end    

    return -angleRadian;
end

--[[
    *获得外接圆的包围盒
    *circle: MobaCircle  圆
    *returns: MobaRect 包围盒
]]
function MobaNMath.GetCircleBoundBox(circle)
    local bBox = MobaRect.rect( circle.center.x - circle.radius,
                                circle.center.y - circle.radius,
                                circle.center.x + circle.radius,
                                circle.center.y + circle.radius);
    return bBox;
end

--[[
    * 返回三角形的外接圆
    * p1: 三角形点1
    * p2: 三角形点2
    * p3: 三角形点3
    * returns: MobaCircle 外接圆
]]    
function MobaNMath.CreateCircle( p1,  p2,  p3)

    if (not MobaNMath.NumberIsEqualZero(p1.y - p2.y) or
        not MobaNMath.NumberIsEqualZero(p2.y - p3.y)) then
    
        local yc, xc;
        local m1 = -(p2.x - p1.x) / (p2.y - p1.y);
        local m2 = -(p3.x - p2.x) / (p3.y - p2.y);
        local mx1 = (p1.x + p2.x) / 2.0;
        local mx2 = (p2.x + p3.x) / 2.0;
        local my1 = (p1.y + p2.y) / 2.0;
        local my2 = (p2.y + p3.y) / 2.0;

        if (MobaNMath.NumberIsEqualZero(p1.y - p2.y)) then
        
            xc = (p2.x + p1.x) / 2.0;
            yc = m2 * (xc - mx2) + my2;
        
        elseif (MobaNMath.NumberIsEqualZero(p3.y - p2.y)) then
        
            xc = (p3.x + p2.x) / 2.0;
            yc = m1 * (xc - mx1) + my1;
        
        else
        
            xc = (m1 * mx1 - m2 * mx2 + my2 - my1) / (m1 - m2);
            yc = m1 * (xc - mx1) + my1;
        end

        local dx = p2.x - xc;
        local dy = p2.y - yc;
        local rsqr = dx * dx + dy * dy;
        local r = math.sqrt(rsqr);

        return MobaCircle.new(cc.p(xc,yc),r);
    end
    return MobaCircle.new(cc.p(0, 0), 0);
end

--[[
    * Calculate the circle tangency.
    * c: MobaCircle 圆 
    * st：point 点
    * returns：table  The circle tangency
]]
function MobaNMath.CalCircleTangency(c , st )

    local dir = cc.p(0,0);
    local dis = cc.pGetLength(cc.pSub(c.center - st));
    local temp= math.sqrt(dis*dis - c.radius*c.radius);
    local sina=temp/dis;
    local cosa=c.radius/dis;
    dir.x=(st.x-c.center.x)/dis*c.radius;
    dir.y=(st.y-c.center.y)/dis*c.radius;

    local res = {cc.p(0,0),cc.p(0,0)};

    res[1].x = c.center.x+(dir.x*cosa-dir.y*sina);
    res[1].y = c.center.y+(dir.x*sina+dir.y*cosa);
    
    res[2].x = c.center.x+(dir.x*cosa+dir.y*sina);
    res[3].y = c.center.y+(-dir.x*sina+dir.y*cosa);

    return res;
end

--[[
    * 将线段终点延长
    * startPos:起始点
    * tarPos:终点
    * length:延长长度
    * return:延长点
]]
function MobaNMath.ExtendPos(startPos,tarPos,length)

    local newPos = tarPos;
    local slopeRate = math.abs((tarPos.y - startPos.y) / (tarPos.x - startPos.x));
    local xLength, yLength;
    if (slopeRate < 1) then
    
        yLength = length;
        xLength = length / slopeRate;
    else
    
        xLength = length;
        yLength = length * slopeRate;
    end

    if (tarPos.x > startPos.x) then
        newPos.x = newPos.x + xLength;
    else
        newPos.x =  newPos.x - xLength;
    end    

    if (tarPos.y > startPos.y) then
        newPos.y = newPos.y + yLength;
    else
        newPos.y = newPos.y - yLength;
    end

    return newPos;
end

--[[
    * 根据线段生成矩形
    * linePath: MobaLine2D 线段
    * returns MobaRect 矩形
]]
function MobaNMath.LineRect(linePath)

    local lineRect = MobaLine2D.new();

    if (linePath:GetStartPoint().x < linePath:GetEndPoint().x) then
        lineRect.xMin = linePath.GetStartPoint().x;
    else
        lineRect.xMin = linePath.GetEndPoint().x;
    end    

    if (linePath:GetStartPoint().y < linePath:GetEndPoint().y) then
        lineRect.yMin = linePath:GetStartPoint().y;
    else
        lineRect.yMin = linePath:GetEndPoint().y;
    end

    lineRect.width = math.abs(linePath:GetEndPoint().x - linePath:GetStartPoint().x);
    lineRect.height = math.abs(linePath:GetEndPoint().y - linePath:GetStartPoint().y);

    return lineRect;
end

------------------------------------------------------------------
-- Cross
------------------------------------------------------------------

--[[
    * 取得2点得叉积 
    * r=multiply(sp,ep,op),得到(sp-op)*(ep-op)的叉积 
    * r>0:ep在矢量opsp的逆时针方向； 
    * r=0：opspep三点共线； 
    * r<0:ep在矢量opsp的顺时针方向 
    * p1:点1
    * p2:点2 
    * returns 叉积
]]
function MobaNMath.CrossProduct(p1,p2)
    return (p1.x * p2.y - p1.y * p2.x);
end

--[[
	* 判断线段是否相交
	* sp1: line1 开始点
	* ep1: line1 结束点
	* sp2: line2 开始点
	* ep2: line2 结束点
	* returns bool 是否相交
]]
function MobaNMath.CheckCrossByPoints( sp1,  ep1,  sp2,  ep2)

    if (math.max(sp1.x, ep1.x) < math.min(sp2.x, ep2.x)) then
        return false;
    end

    if (math.min(sp1.x, ep1.x) > math.max(sp2.x, ep2.x)) then
        return false;
    end

    if (math.max(sp1.y, ep1.y) < math.min(sp2.y, ep2.y)) then
        return false;
    end

    if (math.min(sp1.y, ep1.y) > math.max(sp2.y, ep2.y)) then
        return false;
    end

    local temp1 = MobaNMath.CrossProduct(cc.pSub(sp1,sp2), cc.pSub(ep2,sp2)) * MobaNMath.CrossProduct(cc.pSub(ep2,sp2), cc.pSub(ep1,sp2));
    local temp2 = MobaNMath.CrossProduct(cc.pSub(sp2,sp1), cc.pSub(ep1,sp1)) * MobaNMath.CrossProduct(cc.pSub(ep1,sp1), cc.pSub(ep2,sp1));

    if ((temp1 >= 0) and (temp2 >= 0)) then
        return true;
    end

    return false;
end

--[[
    * 判断矩形是否相交
    * rec1: 矩形1
    * rec2: 矩形2
    * returns:是否相交
]]
function MobaNMath.CheckCrossByRect( rec1,  rec2)

    local ret = MobaRect.new();
    ret.xMin = math.max(rec1.xMin, rec2.xMin);
    ret.xMax = math.min(rec1.xMax, rec2.xMax);
    ret.yMin = math.max(rec1.yMin, rec2.yMin);
    ret.yMax = math.min(rec1.yMax, rec2.yMax);

    if (ret.xMin > ret.xMax or ret.yMin > ret.yMax) then
        -- no intersection, return empty
        return false;
    end
    return true;
end

--[[
    * 判断线段和三角形是否相交
    * line： MobaLine2D 线段
    * tri： MobaTriangle 三角形
    * returns： bool true/false
]]
function MobaNMath.CheckCrossByLineAndTriangle(line , tri )
    for i=1,3 do
        local lineTri = tri:GetSide(i);
        if(MobaNMath.CheckCrossByPoints(line:GetStartPoint() , line:GetEndPoint() , lineTri:GetStartPoint() , lineTri:GetEndPoint())) then
            return true;
        end
    end
    return false;
end

--[[
    * 判断线段和圆是否相交
    * line: MobaLine2D 线段
    * pos：point 圆心点
    * radius：number 半径
    * returns：bool true/false
]]
function MobaNMath.CheckCrossByLineAndPointRadius(line , pos , radius )

    local fDis = line:GetLength();
    
    local d = cc.p(0,0);
    d.x = (line:GetEndPoint().x - line:GetStartPoint().x) / fDis;
    d.y = (line:GetEndPoint().y - line:GetStartPoint().y) / fDis;
    
    local E = cc.p(0,0);
    E.x = pos.x - line:GetStartPoint().x;
    E.y = pos.y - line:GetStartPoint().y;
    
    local a = E.x * d.x + E.y * d.y;
    local a2 = a * a;
    
    local e2 = E.x * E.x + E.y * E.y;
    
    local r2 = radius * radius;
    
    if ((r2 - e2 + a2) < 0) then
    
        return false;  
    end

    return true;
end

--[[
    * 判断线段和圆是否相交
    * line: MobaLine2D 线段
    * cir: MobaCircle 圆
    * returns：bool true/false
]]
function MobaNMath.CheckCross(line ,cir )
    return  MobaNMath.CheckCrossByLineAndPointRadius(line , cir.center , cir.radius);
end

------------------------------------------------------------------
-- Equal
------------------------------------------------------------------

--[[
	* 点是否相等
	* pos1 : 一个点
	* pos2 : 另一个点
	* retur bool 
]]
function MobaNMath.PointIsEqual(pos1,pos2)
	if MobaNMath.NumberIsEqualZero(pos1.x - pos2.x) and MobaNMath.NumberIsEqualZero(pos1.y - pos2.y) then
		return true;
	end
	return false;
end

--[[ 
	* 点是否等于0
    * pos：点
    * return bool 
]]
function MobaNMath.PointIsEqualZero(pos)
    if (MobaNMath.NumberIsEqualZero(pos.x) and MobaNMath.NumberIsEqualZero(pos.y)) then
        return true;
    else
        return false;
    end    
end

--[[ 
	* 检查浮点数误差
	* number 浮点数
	* return bool 
]]      
function MobaNMath.NumberIsEqualZero(number)
    if (math.abs(number) <= EPSILON) then
        return true;
    else
        return false;
    end
end

return MobaNMath;