-- Author: zhang dongli
-- Date: 2015-5-9
-- Navigation Mesh 矩形

MobaRect = class("MobaRect");

function MobaRect.rect(xMin,yMin,xMax,yMax)
	local obj = MobaRect.new();
	obj.xMin = xMin;
	obj.yMin = yMin;
	obj.xMax = xMax;
	obj.yMax = yMax;

	obj.x = xMin;
	obj.y = yMin;
	obj.width = math.abs(obj.xMax - obj.xMin);
	obj.height = math.abs(obj.yMax - obj.yMin);
	return obj;
end

function MobaRect:ctor()
	self.xMin = 0;
	self.yMin = 0;
	self.xMax = 0;
	self.yMax = 0;

	self.x = 0;
	self.y = 0;
	self.width = 0;
	self.height = 0;
end

--[[
	* 判断一个点是否在矩形框内
]]
function MobaRect:Contains(point)
	return point.x >= self.xMin and point.x < self.xMax and point.y >= self.yMin and point.y < self.yMax;
end

return MobaRect;