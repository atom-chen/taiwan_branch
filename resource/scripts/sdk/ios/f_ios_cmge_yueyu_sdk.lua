--[[--
    cmge 越狱ios sdk
--]]--
local f_ios_cmge_yueyu_sdk = class("f_ios_cmge_yueyu_sdk", function()
    return fc.FSdkManager:getInstance()
end)


function f_ios_cmge_yueyu_sdk:ctor()
	self.m_sdk_info = 
	{
		[2] = {"P10283", "D10034", "yfhd50btje46j19xcyom", "M1052"},--yueyu cmge
		[4] = {"P10674", "D10034", "yfhd50btje46j19xcyom", "M1052"},--web cmge
		[5] = {"P10675", "D10034", "yfhd50btje46j19xcyom", "M1052"}, --wap cmge
		[10] = {"P11038", "D10026", "35wrszfgzf2236n3160n", "M1044"} --cmge 正版参数
	}
	self.m_cmge_vertifiy_server = {["ip"] = "118.192.76.178",  ["port"] = 20000}
	self.m_current_save_trascation = nil
	
	self.event_init = function()
		self:init_sdk()
	end
	g_game.g_eventManager:registerLuaEvent(g_game.g_f_lua_game_event.F_LUA_SDK_INIT, self.event_init)
	
	self.event_showLogin = function()
		self:show_sdk_view()
	end
	g_game.g_eventManager:registerLuaEvent(g_game.g_f_lua_game_event.F_LUA_SDK_SHOW_LOGIN, self.event_showLogin)
	
	self.event_changeUser = function()
		self:change_sdk_user()
	end
	g_game.g_eventManager:registerLuaEvent(g_game.g_f_lua_game_event.F_LUA_SDK_LOGIN_CHANGE_ACCOUNT, self.event_changeUser)
	
	self.event_openBBS = function()
		self:open_bbs_center()
	end
	g_game.g_eventManager:registerLuaEvent(g_game.g_f_lua_game_event.F_LUA_SDK_PP_OPEN_BBS, self.event_openBBS)
	
	
	
	--充值	
	self.getTransitionInfo= function(msg)
		self:responseTranscationInfoFromGameServer(msg)
	end
	g_game.g_netManager:registerMessage(g_network_message_type.SC_TRANSACTION_INFO,self.getTransitionInfo)
	
		
	self.getBuyResultFromGameServer= function(msg)
		self:responseBuyResultFromGameServer(msg)
	end
	g_game.g_netManager:registerMessage(g_network_message_type.SC_TRANSACTION, self.getBuyResultFromGameServer)
	
	self.event_iap_products_load = function(productsList)
		self:loadProductsFromServer(productsList)
	end
	g_game.g_eventManager:registerLuaEvent(g_game.g_f_lua_game_event.F_IAP_PRODUCLIST_LOAD, self.event_iap_products_load)
	
	
	self.event_iap_buy = function(data)
		self:iapBuyItem(data)
	end
	g_game.g_eventManager:registerLuaEvent(g_game.g_f_lua_game_event.F_IAP_BUY_ITEM, self.event_iap_buy)
	
	
	self.event_check_native_pay = function()
		self:checkNativePayment()
	end
	g_game.g_eventManager:registerLuaEvent(g_game.g_f_lua_game_event.F_IAP_CHECK_NATIVE_PAY, self.event_check_native_pay)
	
	
	g_game.g_f_sdk_layout_define["isShowBBS_center"] = true
end


-------------------------------------------------------------------------------
-- @function [parent=#f_ios_cmge_yueyu_sdk] init_sdk
-- 初始化sdk
-------------------------------------------------------------------------------
function f_ios_cmge_yueyu_sdk:init_sdk()
	self:setCmgeVertifiyServer(self.m_cmge_vertifiy_server["ip"], self.m_cmge_vertifiy_server["port"])
end


-------------------------------------------------------------------------------
-- @function [parent=#f_ios_cmge_yueyu_sdk] show_sdk_view
-- 显示sdk界面
-------------------------------------------------------------------------------
function f_ios_cmge_yueyu_sdk:show_sdk_view()
	send_lua_event(g_game.g_f_lua_game_event.F_LUA_NETWORK_LOADING)
	
	local loginCallback = function(type, username, uind)
		send_lua_event(g_game.g_f_lua_game_event.F_LUA_CLOSE_NETWORK_LOADING)
		local loginResult = {}
		if type >= 0 then
			loginResult["result"] = 0
			loginResult["account"] = username
			loginResult["userid"] = uind
			loginResult["error_des"] = ""
		else
			loginResult["account"] = ""
			loginResult["userid"] = ""
			if type == -1 then
				loginResult["error_des"] = "未知错误"
				loginResult["result"] = g_game.g_f_lua_game_event.F_LUA_SDK_UNKNOW_ERROR
			elseif type == -11 then
				loginResult["error_des"] = "用户未登录,请登录平台帐号!"
				loginResult["result"] = g_game.g_f_lua_game_event.F_LUA_SDK_USER_NEED_LOGIN
			elseif type == -13 then
				loginResult["error_des"] = "用户校验失败,请重新登录平台帐号!"
				loginResult["result"] = g_game.g_f_lua_game_event.F_LUA_SDK_USER_ACCESS_FAILED
			elseif type == -14 then
		  		g_game.startup()		  		
		  		--数据分析sdk
		  		send_lua_event(g_game.g_f_lua_game_event.F_LUA_DATA_USER_LOGOUT)
				return
			end
		end
		send_lua_event_param(g_game.g_f_lua_game_event.F_LUA_SDK_LOGIN_CALLBACK, loginResult)
	end	
	self:setLoginCallbackCmgeSdk(loginCallback)
	
	if g_game.g_game_is_init then
		self:change_sdk_user()
	else
		self:showCmgeSdkLoginView()
	end
	
end

-------------------------------------------------------------------------------
-- @function [parent=#f_ios_cmge_yueyu_sdk] change_sdk_user
-- 更改sdk用户
-------------------------------------------------------------------------------
function f_ios_cmge_yueyu_sdk:change_sdk_user()
	self:switchCmgeSdkUser()
end

-------------------------------------------------------------------------------
-- @function [parent=#f_ios_cmge_yueyu_sdk] open_bbs_center
-- 打开论坛
-------------------------------------------------------------------------------
function f_ios_cmge_yueyu_sdk:open_bbs_center()
	g_game.g_system:openURL("http://bbs.joygame.cn/forum.php?mod=forumdisplay&fid=63")
end


---------------------------------------------------------------------------------
--充值部分

-------------------------------------------------
-- @function [parent=#f_ios_cmge_yueyu_sdk] loadProductsFromServer
-- 使用产品key列表，刷新商店界面
-------------------------------------------------
function f_ios_cmge_yueyu_sdk:loadProductsFromServer(itemList)	
	self.m_products_id_list = itemList
		
	
	self:iapRequestProductsListener(self.m_products_id_list)
end


-------------------------------------------------
-- @function [parent=#f_ios_cmge_yueyu_sdk] iapRequestProductsListener
-- 模拟苹果服务器返回列表
-------------------------------------------------
function f_ios_cmge_yueyu_sdk:iapRequestProductsListener(data)	
	self.m_products_array = {}	

	for key, value in ipairs(data) do 
		local itemInfo = {} 
		itemInfo["iap"] = value["itemKey"]
		itemInfo["info"] = value
		
		table.insert(self.m_products_array, itemInfo)
	end 	
	send_lua_event_param(g_game.g_f_lua_game_event.F_IAP_INIT_SHOP_ITEM, self.m_products_array)
	
end


-------------------------------------------------
-- @function [parent=#f_ios_cmge_yueyu_sdk] checkNativePayment
-- 检查本地存储得收据凭证并进行继续验证
-------------------------------------------------
function f_ios_cmge_yueyu_sdk:checkNativePayment()	
	local transactionList = g_game.g_dataManager:getPaymentTransaction()
	if transactionList then		
		for i,v in ipairs(transactionList) do
			--进入购买流程，需要loading显示阻挡用户进行其他操作
			self:requestTransitionVertifyFromGameServer(v["transactionIdentifier"])
		end
	end
end


-------------------------------------------------
-- @function [parent=#f_ios_cmge_yueyu_sdk] iapBuyItem
-- 请求购买物品的订单id
-------------------------------------------------
function f_ios_cmge_yueyu_sdk:iapBuyItem(data)	
	self.m_current_buy_item_data = data
	
	self:requestTransitionInfoFromGameServer()
end

-------------------------------------------------
-- @function [parent=#f_ios_cmge_yueyu_sdk] buyResultFromCmgeServer
-- 接收cmge服务器返回的购买结果
-------------------------------------------------
function f_ios_cmge_yueyu_sdk:buyResultFromCmgeServer(type)	
	if type == 0 then
		if self.m_current_save_trascation then			
			g_game.g_dataManager:removePaymentTransaction(self.m_current_save_trascation)
			self.m_current_save_trascation = nil
		end	
	end	
	if type == -1 or type == -2 then
		send_lua_event(g_game.g_f_lua_game_event.F_LUA_CLOSE_NETWORK_LOADING)
	elseif type == -3 then
		send_lua_event(g_game.g_f_lua_game_event.F_LUA_CLOSE_NETWORK_LOADING)
	end
end

-------------------------------------------------
-- @function [parent=#f_ios_cmge_yueyu_sdk] responseTranscationInfoFromGameServer
-- 接收游戏服务器返回的订单号等信息
-------------------------------------------------
function f_ios_cmge_yueyu_sdk:responseTranscationInfoFromGameServer(msg)	
	if msg["result"] == 0 then		
		local buyDoneCallback = function(type)
			self:buyResultFromCmgeServer(type)
		end
		self:setBuyItemCmgeSdkListener(buyDoneCallback)
				
		local userInfo = g_game.g_userInfoManager:getUserInfo()
		
		--buy item from pp sdk here
		self:buyItemWithCmgeSdk(self.m_current_buy_item_data["info"]["gold"] .. self.m_current_buy_item_data["info"]["productName"], msg["transactionId"], self.m_current_buy_item_data["info"]["price"])
	
		self.m_current_save_trascation = msg["transactionId"]
		local transcationInfo = {}
		transcationInfo["transactionIdentifier"] = msg["transactionId"]
		transcationInfo["receipt"] = "none"		
		g_game.g_dataManager:savePaymentTransaction(transcationInfo)
		
		
		--sdk事件收集
		local eventData = {}
		eventData["orderId"] = msg["transactionId"]
		eventData["iapId"] = self.m_current_buy_item_data["info"]["itemKey"]
		eventData["amount"] = self.m_current_buy_item_data["info"]["price"]
		eventData["currencyType"] = "CNY"
		eventData["paymentType"] = "cmge支付"
		send_lua_event_param(g_game.g_f_lua_game_event.F_LUA_DATA_USER_CHARGE_START, eventData)
	else
		if self.m_current_buy_item_data["info"]["id"] == g_game.g_f_month_card_info["info"]["id"] then
			g_game.g_utilManager:showMsg("购买月卡失败，请重新购买!")
		else
			g_game.g_utilManager:showMsg("购买元宝失败，请重新购买!")
		end
		send_lua_event_param(g_game.g_f_lua_game_event.F_IAP_BUY_ITEM_RESULT, {["result"] = false, ["productId"] = self.m_current_buy_item_data["info"]["id"]})	
		self.m_current_buy_item_data = nil
	end
end

-------------------------------------------------
-- @function [parent=#f_ios_cmge_yueyu_sdk] requestTransitionInfoFromGameServer
-- 向服务器发送购买请求，并获取订单id
-------------------------------------------------
function f_ios_cmge_yueyu_sdk:requestTransitionInfoFromGameServer()		
	local dataT = {}
	local userInfo = g_game.g_userInfoManager:getUserInfo()
	local dataT = {}
	dataT["roleId"] = userInfo["roleId"]
	dataT["transactionID"] = "none"
	dataT["receipt"] = "none"
	dataT["productId"] = self.m_current_buy_item_data["info"]["id"]
	dataT["flag"] = 0
	g_game.g_netManager:send_message(g_network_message_type.CS_TRANSACTION, dataT)
	
	
end


-------------------------------------------------
-- @function [parent=#f_ios_cmge_yueyu_sdk] requestTransitionVertifyFromGameServer
-- 使用本地缓存的未完成订单，向服务器再次验证
-------------------------------------------------
function f_ios_cmge_yueyu_sdk:requestTransitionVertifyFromGameServer(transcationId)	
	local dataT = {}
	local userInfo = g_game.g_userInfoManager:getUserInfo()
	local dataT = {}
	dataT["roleId"] = userInfo["roleId"]
	dataT["transactionID"] = transcationId
	dataT["receipt"] = "none"
	dataT["productId"] = "none"
	dataT["flag"] = 1
	g_game.g_netManager:send_message(g_network_message_type.CS_TRANSACTION, dataT)
	
	
	print("10053 second transcation Id" .. transcationId)
end


-------------------------------------------------
-- @function [parent=#f_ios_cmge_yueyu_sdk] responseBuyResultFromGameServer
-- 从游戏服务器接收购买物品结果
-------------------------------------------------
function f_ios_cmge_yueyu_sdk:responseBuyResultFromGameServer(msg)	
-- 		["result"] Type:BYTE Size:1 是否成功
-- 		["errorCode"] Type:INTEGER Size:4 失败代码
-- 		["userGold"] Type:INTEGER Size:4 用户gold数量
-- 		["transactionID"] Type:STRING Size:8 交易ID
	
	if msg["result"] == 0 then	--   -2 服务器数据库错误  －1 正在验证   0 成功  1  未验证  2  失败
		g_game.g_userInfoManager:updateUserGold(msg["userGold"])
		
		local transactionId = msg["transactionID"]
		g_game.g_dataManager:removePaymentTransaction(transactionId)
		
		send_lua_event(g_game.g_f_lua_game_event.F_LUA_UPDATE_SHOP_GOLD)
		send_lua_event_param(g_game.g_f_lua_game_event.F_IAP_BUY_ITEM_RESULT, {["result"] = true, ["productId"] = msg["productId"]})
				
		--sdk事件收集
		local eventData = {}
		eventData["orderId"] = msg["transactionID"]
		send_lua_event_param(g_game.g_f_lua_game_event.F_LUA_DATA_USER_CHARGE_BUYITEM_SUCCESS, eventData)
		
		local chData = {}
		chData["currencyAmount"] = msg["money"]
		chData["currencyType"] = "CNY"
		chData["paymentType"] = "cmge支付"		
		send_lua_event_param(g_game.g_f_lua_game_event.F_LUA_DATA_USER_CHARGE_SUCCESS, chData)	
		
	elseif msg["result"] == 1 then
		send_lua_event_param(g_game.g_f_lua_game_event.F_IAP_BUY_ITEM_RESULT, {["result"] = false, ["productId"] = msg["productId"]})
	elseif msg["result"] == 2 then
		local transactionId = msg["transactionID"]
		g_game.g_dataManager:removePaymentTransaction(transactionId)
		
		send_lua_event_param(g_game.g_f_lua_game_event.F_IAP_BUY_ITEM_RESULT, {["result"] = false, ["productId"] = msg["productId"]})
	elseif msg["result"] == -2 or msg["result"] == -1 then
		send_lua_event_param(g_game.g_f_lua_game_event.F_IAP_BUY_ITEM_RESULT, {["result"] = false, ["productId"] = msg["productId"]})
	else
		send_lua_event_param(g_game.g_f_lua_game_event.F_IAP_BUY_ITEM_RESULT, {["result"] = false, ["productId"] = msg["productId"]})
	end
	send_lua_event(g_game.g_f_lua_game_event.F_LUA_CLOSE_NETWORK_LOADING)
end


return f_ios_cmge_yueyu_sdk