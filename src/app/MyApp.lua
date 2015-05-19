
require("config")
require("cocos.init")
require("framework.init")

require("app.navmesh.MobaNMath")
require("app.navmesh.MobaLine2D")
require("app.navmesh.MobaTriangle")
require("app.navmesh.MobaNavTriangle")
require("app.navmesh.MobaWayPoint")
require("app.navmesh.MobaRect")
require("app.navmesh.MobaNavNode")
require("app.navmesh.MobaPolygon")
require("app.navmesh.MobaCircle")
require("app.navmesh.MobaNavUtil")
require("app.navmesh.MobaNavMeshGen")
require("app.navmesh.MobaNavSeeker")


local MyApp = class("MyApp", cc.mvc.AppBase)

function MyApp:ctor()
    MyApp.super.ctor(self)
end

function MyApp:run()
    cc.FileUtils:getInstance():addSearchPath("res/")
    -- self:enterScene("MainScene")
    self:enterScene("MeshScene")
end

return MyApp
