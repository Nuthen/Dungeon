game = {}

function game:enter(prev, hosting, connectAddress)
	self.color = 1
	
	local scrnWidth, scrnHeight = love.graphics.getDimensions()
	self.player = Player:new(scrnWidth/2, scrnHeight/2)
	self.player2 = Player:new(scrnWidth/2, scrnHeight/2)
	
	self.bullets = {}
	self.bullets2 = {}
	
	self.enemies = {}
	
	-- networking
	self.hosting = hosting
	
	self.state = 'waiting'
	--self.state = 'run'
	
	self.winner = nil
	
	self.lastSendTimer = 0
	
	self.packets = {}
	self.bulletPackets = {}
	self.enemyPackets = {}
	self.enemyHitPackets = {}
	
	self.timerDelay = .5
	
	if self.hosting then -- server setup
		self.ip = '*'
		self.port = '22122'
		
		self.host = enet.host_create(self.ip..':'..self.port, 1)
		
		if self.host == nil then
			error("Couldn't initialize host, there is probably another server running on that port")
		end
		
		self.host:compress_with_range_coder()
		self.timer = 0
		
		self.lastEvent = nil
		self.peer = nil
		
		
	
		self.enemySpawnInterval = 5
		self.enemySpawnTimer = 0
		
		self.enemySendInterval = 1
		self.lastEnemySendTimer = 0
	
	else -- client setup
		self.host = enet.host_create()
		self.server = self.host:connect(connectAddress..':22122')
		self.host:compress_with_range_coder()
		
		self.timer = 0
	end
	
	self.playerTween = false

	self.translateX = 0
	self.translateY = 0

	self.bgQuad = love.graphics.newQuad(0, 0, love.window.getWidth()*2, love.window.getHeight()*2, 64, 64)
    self.bgImage = love.graphics.newImage('img/grid.png')
    self.bgImage:setWrap("repeat")
end

function game:update(dt)
	if not self.playerTween and #self.packets > 0 then
		local packet = self.packets[1]
		local timeSent = packet[1]
		local x = packet[2]
		local y = packet[3]
	
		self.playerTween = true
	
		local timeLeft = math.abs(self.timer-self.timerDelay - timeSent)
		tween(timeLeft, self.player2, {x = x, y = y}, 'linear', function()
			self.playerTween = false
		end)
	end

	self.translateX = -self.player.x + love.graphics.getWidth()/2
	self.translateY = -self.player.y + love.graphics.getHeight()/2


	if #self.packets > 0 then
		local packet = self.packets[1]
		local timeSent = packet[1]
		local x = packet[2]
		local y = packet[3]
	
		if self.timer - self.timerDelay > timeSent then
			self.player2.x = x
			self.player2.y = y
			table.remove(self.packets, 1)
		end
	end
	
	if #self.bulletPackets > 0 then
		local packet = self.bulletPackets[1]
		local timeSent = packet[1]
		local x = packet[2]
		local y = packet[3]
		local targetX = packet[4]
		local targetY = packet[5]
	
		if self.timer - self.timerDelay > timeSent then
			table.insert(self.bullets2, Bullet:new(x, y, targetX+self.translateX, targetY+self.translateY))
			table.remove(self.bulletPackets, 1)
		end
	end
	
	-- inefficient
	for i = #self.enemyPackets, 1, -1 do
		local packet = self.enemyPackets[i]
		local timeSent = packet[1]
		local index = packet[2]
		local x = packet[3]
		local y = packet[4]
	
		if self.timer - self.timerDelay > timeSent then
			if not self.enemies[index] then
				self.enemies[index] = Enemy:new(x, y)
			else
				self.enemies[index]:storePacket(timeSent, x, y)
			end
			table.remove(self.enemyPackets, i)
		end
	end
	
	for i = #self.enemyHitPackets, 1, -1 do
		local packet = self.enemyHitPackets[i]
		local timeSent = packet[1]
		local index = packet[2]
	
		if self.timer - self.timerDelay > timeSent then
			if not self.enemies[index] then
				--self.enemies[index] = Enemy:new(x, y)
			else
				self.enemies[index].hit = true
			end
			table.remove(self.enemyHitPackets, i)
		end
	end
	
	-- networking
	if self.hosting then
		self.timer = self.timer + dt
		
		-- check some events, 100ms timeout
		local event = self.host:service(0)
		
		if event then
			self.lastEvent = event
			self.peer = event.peer
			
			if event.type == 'connect' then
				--self.host:broadcast('t|'..math.floor(self.timer*100))
				self.state = 'run'
				self.timer = 0
				
				--self.host:broadcast('c| 2') -- set other player's color to 2
			elseif event.type == 'receive' then
				if string.find(event.data, 'p|') == 1 then -- True if it is piece movement data
					local str = string.gsub(event.data, 'p|', '')
					local playerTable = stringToTable(str)
					
					local timeSent = tonumber(playerTable[1])
					local x = tonumber(playerTable[2])
					local y = tonumber(playerTable[3])
					
					if self.timer - self.timerDelay <= timeSent then
						table.insert(self.packets, {timeSent, x, y})
					else
						self.player2.x = x
						self.player2.y = y
					end
					
				elseif string.find(event.data, 'b|') == 1 then -- True if it is piece movement data
					local str = string.gsub(event.data, 'b|', '')
					local bulletTable = stringToTable(str)
					
					local timeSent = tonumber(bulletTable[1])
					local x = tonumber(bulletTable[2])
					local y = tonumber(bulletTable[3])
					local targetX = tonumber(bulletTable[4])
					local targetY = tonumber(bulletTable[5])
					
					if self.timer - self.timerDelay <= timeSent then
						table.insert(self.bulletPackets, {timeSent, x, y, targetX, targetY})
					else
						table.insert(self.bullets2, Bullet:new(x, y, targetX+self.translateX, targetY+self.translateY))
					end
					
				elseif string.find(event.data, 'h|') == 1 then -- True if it is piece movement data
					local str = string.gsub(event.data, 'h|', '')
					local hitTable = stringToTable(str)
					
					local timeSent = tonumber(hitTable[1])
					local index = tonumber(hitTable[2])
					
					if self.timer - self.timerDelay <= timeSent then
						table.insert(self.enemyHitPackets, {timeSent, index})
					else
						if not self.enemies[index] then
							--self.enemies[index] = Enemy:new(x, y)
						else
							self.enemies[index].hit = true
						end
					end
				end
				
			elseif event.type == 'disconnect' then
				state.switch(menu, 'hostDisconnect')
			end
		end
		
		--[[
		if self.tick >= self.tock then
			self.tick = 0
			self.host:broadcast('t|'..math.floor(self.timer*100))
		end
		]]
	else
		self.timer = self.timer + dt
		
		-- check some events, 100ms timeout
		local event = self.host:service(0)

		if event then
			--event.peer:ping_interval(1000)
			self.lastEvent = event
			self.peer = event.peer
			
			if event.type == 'connect' then
				self.state = 'run'
				self.timer = 0
			
			elseif event.type == 'receive' then
				if string.find(event.data, 'p|') == 1 then -- True if it is piece movement data
					local str = string.gsub(event.data, 'p|', '')
					local playerTable = stringToTable(str)
					
					local timeSent = tonumber(playerTable[1])
					local x = tonumber(playerTable[2])
					local y = tonumber(playerTable[3])
					
					if self.timer - self.timerDelay <= timeSent then
						table.insert(self.packets, {timeSent, x, y})
					else
						self.player2.x = x
						self.player2.y = y
					end
					
				elseif string.find(event.data, 'b|') == 1 then -- True if it is piece movement data
					local str = string.gsub(event.data, 'b|', '')
					local bulletTable = stringToTable(str)
					
					local timeSent = tonumber(bulletTable[1])
					local x = tonumber(bulletTable[2])
					local y = tonumber(bulletTable[3])
					local targetX = tonumber(bulletTable[4])
					local targetY = tonumber(bulletTable[5])
					
					if self.timer - self.timerDelay <= timeSent then
						table.insert(self.bulletPackets, {timeSent, x, y, targetX, targetY})
					else
						table.insert(self.bullets2, Bullet:new(x, y, targetX+self.translateX, targetY+self.translateY))
					end
					
				elseif string.find(event.data, 'e|') == 1 then -- True if it is piece movement data
					local str = string.gsub(event.data, 'e|', '')
					local enemyTable = stringToTable(str)
					
					local timeSent = tonumber(enemyTable[1])
					local index = tonumber(enemyTable[2])
					local x = tonumber(enemyTable[3])
					local y = tonumber(enemyTable[4])
					
					if self.timer - self.timerDelay <= timeSent then
						table.insert(self.enemyPackets, {timeSent, index, x, y})
					else
						if not self.enemies[index] then
							self.enemies[index] = Enemy:new(x, y)
						else
							self.enemies[index].x = x
							self.enemies[index].y = y
						end
					end
					
				elseif string.find(event.data, 'h|') == 1 then -- True if it is piece movement data
					local str = string.gsub(event.data, 'h|', '')
					local hitTable = stringToTable(str)
					
					local timeSent = tonumber(hitTable[1])
					local index = tonumber(hitTable[2])
					
					if self.timer - self.timerDelay <= timeSent then
						table.insert(self.enemyHitPackets, {timeSent, index})
					else
						if not self.enemies[index] then
							--self.enemies[index] = Enemy:new(x, y)
						else
							self.enemies[index].hit = true
						end
					end
				end
				
			elseif event.type == 'disconnect' then
				state.switch(menu, 'clientDisconnect')
			end
		end
	end
	
	
	if self.state == 'run' then
		-- host spawns enemies on an interval
		if self.hosting then
			self.enemySpawnTimer = self.enemySpawnTimer + dt
			if self.enemySpawnTimer > self.enemySpawnInterval then
				self.enemySpawnTimer = 0
				if self.enemySpawnInterval > 2 then
					self.enemySpawnInterval = 5 - self.timer/20
				end
				
				local enemy = Enemy:new()
				table.insert(self.enemies, enemy)
				
				self:sendEnemy(#self.enemies, enemy.x, enemy.y)
			end
			
			
			self.lastEnemySendTimer = self.lastEnemySendTimer + dt
			
			for i, enemy in ipairs(self.enemies) do
				enemy:hostUpdate(dt)
				if self.lastEnemySendTimer > self.enemySendInterval then
					self:sendEnemy(i, enemy.x, enemy.y)
				end
			end
			
			if self.lastEnemySendTimer > self.enemySendInterval then
				self.lastEnemySendTimer = 0
			end
		else
			for i, enemy in ipairs(self.enemies) do
				enemy:clientUpdate(dt)
			end
		end
	
		self.lastSendTimer = self.lastSendTimer + dt
		dx, dy = self.player:update(dt)
		
		if dx ~= 0 or dy ~= 0 then
			if self.lastSendTimer > .2 then
				self.lastSendTimer = 0
				self:sendMove()
			end
		end
		
		for k, bullet in pairs(self.bullets) do
			bullet:update(dt)
			bullet:checkHit()
		end
		for k, bullet in pairs(self.bullets2) do
			bullet:update(dt)
		end
		
		for i = #self.bullets, 1, -1 do
			if self.bullets[i].destroy then
				table.remove(self.bullets, i)
			end
		end
		for i = #self.bullets2, 1, -1 do
			if self.bullets2[i].destroy then
				table.remove(self.bullets2, i)
			end
		end
	end
end

function game:keypressed(key, isrepeat)
    if console.keypressed(key) then
        return
    end
end

function game:mousepressed(x, y, mbutton)
    if console.mousepressed(x, y, mbutton) then
        return
    end
	
	if self.state == 'run' then
		if mbutton == 'l' then
			table.insert(self.bullets, Bullet:new(self.player.x, self.player.y, x-self.translateX, y-self.translateY))
			self:sendBullet(self.player.x, self.player.y, x-self.translateX, y-self.translateY)
		end
	end
end

function game:draw()
    love.graphics.setFont(font[48])


    love.graphics.draw(self.bgImage, self.bgQuad, -self.player.x, -self.player.y)
	
	love.graphics.translate(self.translateX, self.translateY)
	self.player:draw()
	love.graphics.translate(0, 0)
	self.player2:draw()
	
	for k, enemy in pairs(self.enemies) do
		enemy:draw()
	end
	
	for k, bullet in pairs(self.bullets) do
		bullet:draw()
	end
	for k, bullet in pairs(self.bullets2) do
		bullet:draw()
	end
	
	
	love.graphics.setFont(fontBold[16])
	
	love.graphics.setColor(255, 255, 255)
	love.graphics.print(love.timer.getFPS()..'FPS', 5, 5)
	
	love.graphics.print(#self.bullets..' + '..#self.bullets2..' bullets', 75, 5)
	
	-- networking
	if self.hosting then
		love.graphics.print('Running server on ' .. self.ip .. ':' .. self.port, 5, 25)
		love.graphics.print('Server Time: '..math.floor(self.timer*100)/100, 5, 45)
		love.graphics.print('Sent: '..self.host:total_sent_data()*.000001 ..'MB; Received: '..self.host:total_received_data()*.000001 ..'MB', 5, 85)
	else
		love.graphics.print('Server Time: '..math.floor(self.timer*100)/100, 5, 45)
		love.graphics.print('Sent: '..self.host:total_sent_data()*.000001 ..'MB; Received: '..self.host:total_received_data()*.000001 ..'MB', 5, 85)
	end
	
	if self.lastEvent then
        local msg = 'Last message: '..tostring(self.lastEvent.data)..' from '..tostring(self.peer:index())
        love.graphics.print(msg, 5, 65)
    end
	
	if self.peer then
		love.graphics.print(self.peer:round_trip_time()..'ms', 5, 105)
	end
end


function game:sendMove()
	local x, y = math.floor(self.player.x), math.floor(self.player.y)
	if self.hosting then
		self.host:broadcast('p|'..self.timer..' '..x..' '..y)
	elseif self.peer then
		self.peer:send('p|'..self.timer..' '..x..' '..y)
	end
end

function game:sendBullet(x, y, targetX, targetY)
	x = math.floor(x)
	y = math.floor(y)
	targetX = math.floor(targetX)
	targetY = math.floor(targetY)
	
	if self.hosting then
		self.host:broadcast('b|'..self.timer..' '..x..' '..y..' '..targetX..' '..targetY)
	elseif self.peer then
		self.peer:send('b|'..self.timer..' '..x..' '..y..' '..targetX..' '..targetY)
	end
end

function game:sendEnemy(index, x, y)
	x = math.floor(x)
	y = math.floor(y)
	
	if self.hosting then
		self.host:broadcast('e|'..self.timer..' '..index..' '..x..' '..y)
	elseif self.peer then
		self.peer:send('e|'..self.timer..' '..index..' '..x..' '..y)
	end
end

function game:sendEnemyHit(index)
	if self.hosting then
		self.host:broadcast('h|'..self.timer..' '..index)
	elseif self.peer then
		self.peer:send('h|'..self.timer..' '..index)
	end
end