-- Author: zhang dongli
-- Date: 2015-5-9
-- Navigation Mesh 圆

MobaCircle = class("MobaCircle");

function MobaCircle:ctor(cen, r)
	--圆心
    self.center = cc.p(cen.x,cen.y);
	 
    --半径
    self.radius = r;
end

return MobaCircle;