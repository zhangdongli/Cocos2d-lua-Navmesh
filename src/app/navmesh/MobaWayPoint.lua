-- Author: zhang dongli
-- Date: 2015-5-9
-- Navigation Mesh 路径点

MobaWayPoint = class("MobaWayPoint");

function MobaWayPoint:ctor( pos,  tri)
	self.m_cPoint = pos;       --位置点
	self.m_cTriangle = tri;    --所在三角形
end

--[[
	* 获取路径点
]]
function MobaWayPoint:GetPoint()
    return self.m_cPoint;
end

--[[
	* 获取路径三角形
]]
function MobaWayPoint:GetTriangle()
    return self.m_cTriangle;
end

return MobaWayPoint;