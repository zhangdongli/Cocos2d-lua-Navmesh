--
-- Author: zhang dongli
-- Date: 2015-5-9
-- Navigation Mesh 多边形节点

MobaNavNode = class("MobaNavNode");

function MobaNavNode.node(point,  isin,  bMain)
	local obj = MobaNavNode.new();
	obj.vertex = point;
    obj.isIns = isin;
    obj.isMain = bMain;
    obj.passed = false;
    obj.o = false;
    return obj;
end

function MobaNavNode:ctor()
	self.vertex = cc.p(0,0);     --顶点
    self.passed = false;      	 --是否被访问过
    self.isMain = false;         --是否主多边形顶点
    self.o = false;              --是否输出点
    self.isIns = false;          --是否交点
    self.other = nil;            --交点用，另个多边形上的节点
    self.next = nil;             --后面一个点
end

return MobaNavNode;