--
-- Author: zhang dongli
-- Date: 2015-5-9
-- Navigation Mesh NavUtil

MobaNavUtil = class("MobaNavUtil");

--[[
	* 用于合并传进来的多边形数组，返回合并后的多边形数组，
	* 如果生成了孤岛，则孤岛的tag标志递增
	* polys: table 多边形集合
	* returns1: PolyResCode 合并结果
    * returns2: polys 合并结果集合
]]
function MobaNavUtil.UnionAllPolygon(polys)
    local tag = 1;

    --所有多边形顶点按照顺时针排序
    for i,poly in ipairs(polys) do poly:CW() end;    

    --将所有多边形两两合并
    local i,j,max = 1,1,#polys;
    local p1,p2 = nil,nil;
    while i <= max do
        p1 = polys[i];--取得多边形1
        j = 1;
        while j <= max do
            p2 = polys[j];--取得多边形2
            --如果2个多边形不相等
            if ( i ~= j and p1 ~= p2) then 
                --合并两个交叉的多边形(多边形必须先转换为顺时针方向，调用CW()函数!)
                local result,polyResult = p1:Union(p2);

                --如果合并成功 且 合并后的多边形不为0个
                if (result == PolyResCode.Success and #polyResult > 0) then

                    -- 从多边形集合中移除2个合并之前的多边形
                    table.removebyvalue(polys, p1);
                    table.removebyvalue(polys, p2);

                    -- 将合并后的多边形添加到多边形集合中
                    for i,poly in ipairs(polyResult) do
                        if (not poly:IsCW()) then
                            poly:SetTag(tag);--如果逆时针说明这个多边形是孤岛
                            tag = tag + 1;
                        end
                        polys[#polys + 1] = poly;
                    end
                    
                    -- 调整数量
                    max = #polys;

                    -- 从头再来一次
                    i = 0;
                    break;
                end
            end
            j = j + 1;            
        end
        i = i + 1;
    end
    return PolyResCode.Success,polys;
end

--[[
    * 合并两个节点列表，生成交点，并按顺时针序插入到顶点表中
    * c0: table 主多边形顶点表，并返回插入交点后的顶点表
    * c1: table 合并多边形顶点表，并返回插入交点后的顶点表
    * return 1 合并结果
    * return 2 交点个数
]]
function MobaNavUtil.NavNodeIntersectPoint(c0, c1)
    local nInsCnt = 0; --交点个数

    local startNode0 = c0[1];--取得主顶点集合的开始顶点
    local startNode1 = nil;  --合并顶点集合的开始顶点

    local line0 = nil; --主顶点集合的线段1
    local line1 = nil; --合并顶点集合的线段2

    local hasIns = false;           --是否相交
    local insPoint = cc.p(0,0);     --相交点
    local insResult = -1;           --相交类型  
    local insPotIndex = -1;         --相交边的下标
    
    while (startNode0 ~= nil) do
    
        -- 判断是否到末点了
        if (startNode0.next == nil) then
            --最后一个顶点和第一个顶点相连，构成最后一条边。
            line0 = MobaLine2D.new(startNode0.vertex, c0[1].vertex);
        else
            --当前顶点和它的下一顶点相连，构成当前边
            line0 = MobaLine2D.new(startNode0.vertex, startNode0.next.vertex);
        end

        startNode1 = c1[1]; --取得合并顶点集合的开始顶点
        hasIns = false;     --查找之前，设置为没有相交

        while (startNode1 ~= nil) do
        
            if (startNode1.next == nil) then
                line1 = MobaLine2D.new(startNode1.vertex, c1[1].vertex);
            else
                line1 = MobaLine2D.new(startNode1.vertex, startNode1.next.vertex);
            end 

            -- 计算两条二维线段的交点
            insResult,insPoint =  line0:Intersection(line1);

            if (insResult == LineCrossState.CROSS) then
                
                --查找 insPoint（交点）是否在主顶点列表里面
                --如果在，说明两个多边形存在公用顶点的情况
                insPotIndex = -1; --计算之前置为-1
                insResult,insPotIndex = MobaNavUtil.NavNodeGetNodeIndex(c0, insPoint);
                
                --如果交点不在主多边形的顶点上
                if (insResult == PolyResCode.ErrNotInside) then
                
                    nInsCnt = nInsCnt + 1;--交点个数加1
                    local node0 = MobaNavNode.node(insPoint, true, true);--为主顶点，生成新的顶点
                    local node1 = MobaNavNode.node(insPoint, true, false);--为合并顶点，生成新的顶点

                    table.insert(c0,node0);--加入主顶点集合中
                    table.insert(c1,node1);--加入合并顶点集合中

                    --2个顶点互相指向
                    node0.other = node1;
                    node1.other = node0;

                    --插入主顶点队列
                    node0.next = startNode0.next;
                    startNode0.next = node0;

                    --插入合并顶点队列
                    node1.next = startNode1.next;
                    startNode1.next = node1;

                    --如果line1的结束点在，line0的右边
                    if (line0:ClassifyPoint(line1.GetEndPoint()) == PointSide.RIGHT_SIDE) then
                        node0.o = true; --是输出点
                        node1.o = true; 
                    end

                    hasIns = true;
                    break;
                end
            end

            -- 转到下一个要合并的顶点
            startNode1 = startNode1.next;
        end

        --如果么有相交，转到下一主顶点
        --如果相交，那么当前点和交点组成line0,再继续判断是否和下个line1相交
        if (not hasIns) then startNode0 = startNode0.next; end
    end

    return PolyResCode.Success,nInsCnt;
end

--[[
    * 查找point是否在节点列表里面
    * nodeList: 节点列表
    * point: 用于查找的节点
    * returns1: 如果在里面，返回成功，否则返回不在
    * returns2: 返回节点索引
]]
function MobaNavUtil.NavNodeGetNodeIndex(nodeList, point)
    local pIndex = -1;
    for i,node in ipairs(nodeList) do
        if (MobaNMath.PointIsEqual(node.vertex, point)) then
            pIndex = i;
            return PolyResCode.Success,pIndex;
        end
    end
    return PolyResCode.ErrNotInside,pIndex;
end

--[[
    * 合并两个节点列表为一个多边形，结果为顺时针序( 生成的内部孔洞多边形为逆时针序)
    * mainNode:  主顶点列表
    * subNode:   要合并的顶点列表
    * returns1:  PolyResCode 合并结果
    * returns2:  合并的多变形集合
]]
function MobaNavUtil.LinkToPolygon(mainNode,subNode)

    local polyRes = {};--合并后的多边形集合

    for i,currNode in ipairs(mainNode) do
        -- 选择一个没有访问过的交点做起始点
        if (currNode.isIns and not currNode.passed) then
        
            local points = {};
            while (currNode ~= nil) do
            
                currNode.passed = true;--设置为被访问过

                --交点转换
                if (currNode.isIns) then--如果是交点
                
                    currNode.other.passed = true;--指向的相同位置交点，也设置为访问过

                    if (not currNode.o) then --该交点为进点（跟踪裁剪多边形边界）

                        if (currNode.isMain) then --当前点在主多边形中
                            currNode = currNode.other; --切换到裁剪多边形中
                        end
                    else
                        --该交点为出点（跟踪主多边形边界）
                        if ( not currNode.isMain) then -- 当前点在裁剪多边形中
                            currNode = currNode.other; --切换到主多边形中
                        end
                    end
                end

               points[#points + 1] = currNode.vertex;

                if (currNode.next ==  nil) then
                    if (currNode.isMain) then
                        currNode = mainNode[1];
                    else
                        currNode = subNode[1];
                    end
                else
                    currNode = currNode.next;
                end    

                --如果当前顶点 和 第一个处理的交点相等，那么说明处理完毕
                if (MobaNMath.PointIsEqual(currNode.vertex,points[1])) then
                    break;
                end
            end

            -- 删除重复顶点
            local poly = MobaPolygon.Polygon(points);
            poly:DelRepeatPoint();
            polyRes[#polyRes + 1] = poly;
        end
    end
    return PolyResCode.Success,polyRes;
end

return MobaNavUtil;