--[[--
    新手指引
    选择殿选
    步骤
--]]--

local f_guidelines_26 = class("f_guidelines_26")
f_guidelines_26.__index = f_guidelines_26

-------------------------------------------------
-- @function [parent=#f_guidelines_26] ctor
-------------------------------------------------
function f_guidelines_26:ctor()	
	self.m_guidelines_manager = nil
	
	self.m_time = 0
	self.m_finish = false
	
	self.STATE_INIT			= 1
	self.STATE_CHECK		= 2
	self.STATE_FINISH		= 3
	self.STATE_EXIT			= 4
	
	self.m_state_function_array = {}
	
	local state_init = function(dt)
		self:state_Init(dt)
	end
	self.m_state_function_array[self.STATE_INIT] = state_init
	
	local state_check = function(dt)
		self:state_Check(dt)
	end
	self.m_state_function_array[self.STATE_CHECK] = state_check
	
	local state_finish = function(dt)
		self:state_Finish(dt)
	end
	self.m_state_function_array[self.STATE_FINISH] = state_finish
	
	local state_exit = function(dt)
		self:state_Exit(dt)
	end
	self.m_state_function_array[self.STATE_EXIT] = state_exit
	
	self.m_current_state	= self.STATE_INIT
end

-------------------------------------------------------------------------------
-- @function [parent=#f_guidelines_26] setGuidelinesManager
-- 设置新手指引管理
-------------------------------------------------------------------------------
function f_guidelines_26:setGuidelinesManager(manager)	
	self.m_guidelines_manager = manager
end

-------------------------------------------------------------------------------
-- @function [parent=#f_guidelines_26] guidelinesNextIndex
-- 获取下一步指引index
-------------------------------------------------------------------------------
function f_guidelines_26:guidelinesNextIndex()	
	return 27
end


-------------------------------------------------------------------------------
-- @function [parent=#f_guidelines_26] guidelinesFinish
-- 判断当前指引是否结束
-------------------------------------------------------------------------------
function f_guidelines_26:guidelinesFinish()	
	return self.m_finish
end


-------------------------------------------------------------------------------
-- @function [parent=#f_guidelines_26] update
-- 新手指引更新函数
-------------------------------------------------------------------------------
function f_guidelines_26:update(dt)	
	self.m_state_function_array[self.m_current_state](dt)
end


-------------------------------------------------------------------------------
-- @function [parent=#f_guidelines_26] state_Init
-- 初始化当前状态
-------------------------------------------------------------------------------
function f_guidelines_26:state_Init(dt)	
	if g_game.g_current_scene_type == g_game.SCENE_TYPE_GAME then		
		if not g_game.g_panelManager:isUiPanelShow("keju_xuanxiu_shangcheng") then
			return 
		end
		
		local shangchengPanel = g_game.g_panelManager:getUiPanel("keju_xuanxiu_shangcheng")
		local xuanxiuPanel = shangchengPanel.m_xuanxiu	
		if xuanxiuPanel then
			local dianxuanBtn = xuanxiuPanel.m_componentTable["xx_dianxuan_button"]
			if dianxuanBtn then		
				local stencilPanel = self.m_guidelines_manager:getComponent()
				stencilPanel:enableAllStencil(true)
				stencilPanel:scaleFullScreen(false)		
				stencilPanel:enableStencil(true)
						
				local posx, posy = dianxuanBtn:getPosition()
				local pos = dianxuanBtn:getParent():convertToWorldSpace(cc.p(posx, posy))			
				stencilPanel:setRectType(pos, dianxuanBtn:getSize(), false, false)
				
			    local guidelinesBtn = fc.FScaleButton:create()
			    guidelinesBtn:setButtonImage("batch_ui/xuanxiu_deng.png")

				stencilPanel:showIndicateComponent(guidelinesBtn, pos, dianxuanBtn:getSize())
				stencilPanel:showIndicateAnimation(pos, dianxuanBtn:getSize())
				
				self.guidelinesPanel = f_guidelines_text_show_panel.static_create()
				self.guidelinesPanel:panelInitBeforePopup()		
				stencilPanel:appendComponent(self.guidelinesPanel)
				self.guidelinesPanel:setComponentZOrder(100)
				local sizeT = self.guidelinesPanel:getSize()
				self.guidelinesPanel:setAnchorPoint(cc.p(0.5, 0.5))
				local stencilSize = stencilPanel:getStencilSize() 
				self.guidelinesPanel:setPositionInContainer(cc.p(stencilSize.width/2, stencilSize.height/2))
				self.guidelinesPanel:setSwallowsTouches(false)
				self.guidelinesPanel:showText(self.m_guidelines_manager:getGuidelinesText(26))
				self.guidelinesPanel:setGuidlinesPersonImage(self.m_guidelines_manager:getGuidelinesPerson(26), false)
				
				
				
				--注册监听函数
				self.event_openQindianXiunv = function()
					if self.m_current_state == self.STATE_CHECK then	
						stencilPanel:enableStencil(false)
						self.m_current_state = self.STATE_FINISH
					end
				end
				g_game.g_eventManager:registerLuaEvent(g_game.g_f_lua_game_event.F_LUA_GUIDELINES_OPEN_QINDIAN_XUANXIU, self.event_openQindianXiunv)
				
		
				self.m_current_state = self.STATE_CHECK
				self.m_time = 0
			end
		end
		

	end
end

-------------------------------------------------------------------------------
-- @function [parent=#f_guidelines_26] state_Check
-- 检查万岁是否结束
-------------------------------------------------------------------------------
function f_guidelines_26:state_Check(dt)	
	self.m_time = self.m_time + dt
	
end

-------------------------------------------------------------------------------
-- @function [parent=#f_guidelines_26] state_Finish
-- 结束当前步骤指引
-------------------------------------------------------------------------------
function f_guidelines_26:state_Finish(dt)	
	g_game.g_userInfoManager:requestRecordGuidleStep(5)
	self.m_current_state = self.STATE_EXIT
	
	local stencilPanel = self.m_guidelines_manager:getComponent()
	stencilPanel:setRectType(cc.p(0,0), cc.size(0,0), true, false)
	stencilPanel:hideIndicateAnimation()
	stencilPanel:hideIndicateComponent()
	stencilPanel:setVisible(false)
	if self.guidelinesPanel then
		stencilPanel:deleteComponent(self.guidelinesPanel)
		self.guidelinesPanel = nil
	end
	
	g_game.g_eventManager:removeLuaEventFunction(g_game.g_f_lua_game_event.F_LUA_GUIDELINES_OPEN_QINDIAN_XUANXIU, self.event_openQindianXiunv)

end

-------------------------------------------------------------------------------
-- @function [parent=#f_guidelines_26] state_Exit
-- 退出当前步骤指引
-------------------------------------------------------------------------------
function f_guidelines_26:state_Exit(dt)	
	self.m_finish = true
end


return f_guidelines_26