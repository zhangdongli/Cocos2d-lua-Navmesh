-- Author: zhang dongli
-- Date: 2015-5-9
-- Navigation Mesh 导航使用三角形 继承至 MobaTriangle

MobaNavTriangle = class("MobaNavTriangle", MobaTriangle);

function MobaNavTriangle:ctor()
	self.super.ctor(self);

	-- 寻路相关参数
    self.m_iSessionID = -1;   	 --
    self.m_iParentID = -1;       --父节点ID
    self.m_bIsOpen = false;      --是否打开

    -- 评估相关
    self.m_dHValue = 0.0;   	  --H评估值
    self.m_dGValue = 0.0;   	  --G评估值
    self.m_iInWallIndex = -1; 	  --穿入边索引
    self.m_iOutWallIndex = -1;    --穿出边索引
end

--[[
	*重置
]] 
function MobaNavTriangle:Reset()
    self.m_iSessionID = -1;   	
    self.m_iParentID = -1;       
    self.m_bIsOpen = false;      
    self.m_dHValue = 0.0;   	  
    self.m_dGValue = 0.0;   	  
    self.m_iInWallIndex = -1; 	  
    self.m_iOutWallIndex = -1;    
end

--[[
	*设置当前三角形的穿入边
]]
function MobaNavTriangle:SetArrivalWall(neighborID)

    if (neighborID == -1) then
        return;
    end
    self.m_iInWallIndex = self:GetWallIndex(neighborID);
end

--[[
	* 获得通过当前三角形的花费
    * neighborID int 三角形id
	* returns number 花费
]]
function MobaNavTriangle:GetCost(neighborID)

    local outWallIndex = self:GetWallIndex(neighborID);
    if (self.m_iInWallIndex == -1) then
        return 0;
    elseif (self.m_iInWallIndex ~= 0)then
        return self.m_vecWallDistance[2];
    elseif (outWallIndex == 1) then
        return self.m_vecWallDistance[1];
    else
        return self.m_vecWallDistance[3];
    end
end

--[[
	* 计算三角形估价函数（h值）
	* 使用该三角形的中心点（3个顶点的平均值）到路径终点的x和y方向的距离。
	* endPos 终点
]]
function MobaNavTriangle:CalcHeuristic(endPos)
    local xDelta = math.abs(self.m_cCenter.x - endPos.x);
    local yDelta = math.abs(self.m_cCenter.y - endPos.y);
    self.m_dHValue = math.sqrt(xDelta * xDelta + yDelta * yDelta);
end

--[[
	* 获取SESSIONID
]]
function MobaNavTriangle:GetSessionID()
    return self.m_iSessionID;
end

--[[
	* 设置SESSIONID
]]
function MobaNavTriangle:SetSessionID(id)
    self.m_iSessionID = id;
end

--[[
	* 获取父节点ID
]]
function MobaNavTriangle:GetParentID()
    return self.m_iParentID;
end

--[[
	* 设置父节点
]]
function MobaNavTriangle:SetParentID(id)
    self.m_iParentID = id;
end

--[[
	* 获取是否打开
]]
function MobaNavTriangle:GetOpen()
    return self.m_bIsOpen;
end

--[[
	* 设置打开状态
]]
function MobaNavTriangle:SetOpen(val)
    self.m_bIsOpen = val;
end

--[[
	* 获取H评估值
]]
function MobaNavTriangle:GetHValue()
    return self.m_dHValue;
end

--[[
	* 获取G评估值
]]
function MobaNavTriangle:GetGValue()
    return self.m_dGValue;
end

--[[
	* 设置G评估值
]]
function MobaNavTriangle:SetGValue(val)
    self.m_dGValue = val;
end

--[[
	* 获取穿入边索引
]]
function MobaNavTriangle:InWallIndex()
    return self.m_iInWallIndex;
end

--[[
	*  获取穿出边索引
]]
function MobaNavTriangle:GetOutWallIndex()
    return self.m_iOutWallIndex;
end

--[[
	* 设置穿出边索引
]]
function MobaNavTriangle:SetOutWallIndex(index)
    self.m_iOutWallIndex = index;
end

return MobaNavTriangle;