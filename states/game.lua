game = {}

function game:enter(prev, hosting)
	self.color = 1
	
	local scrnWidth, scrnHeight = love.graphics.getDimensions()
	self.player = Player:new(scrnWidth/2, scrnHeight/2)
	self.player2 = Player:new(scrnWidth/2, scrnHeight/2)
	
	
	-- networking
	self.hosting = hosting
	
	self.state = 'waiting'
	--self.state = 'run'
	
	self.winner = nil
	
	self.lastSendTimer = 0
	
	self.packets = {}
	
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
	
	else -- client setup
		self.host = enet.host_create()
		self.server = self.host:connect('69.137.215.69:22122')
		--self.server = self.host:connect('localhost:22122')
		self.host:compress_with_range_coder()
		
		self.timer = 0
	end
	
	self.enemyTween = false
end

function game:update(dt)
	if not self.enemyTween and #self.packets > 0 then
		local packet = self.packets[1]
		local timeSent = packet[1]
		local x = packet[2]
		local y = packet[3]
	
		self.enemyTween = true
	
		local timeLeft = math.abs(self.timer-self.timerDelay - timeSent)
		tween(timeLeft, self.player2, {x = x, y = y}, 'linear', function()
			self.enemyTween = false
		end)
	end


	if #self.packets > 0 then
		local packet = self.packets[1]
		local timeSent = packet[1]
		local x = packet[2]
		local y = packet[3]
	
		if self.timer - self.timerDelay > timeSent then
			self.player2.x = x
			self.player2.y = y
			table.remove(self.packets, 1)
		else
			local timeLeft = timeSent - self.timer-self.timerDelay
			
			local speedX = (-self.player2.x - x)/timeLeft
			local speedY = (-self.player2.y - y)/timeLeft
			self.player2.x = self.player2.x + speedX*dt
			self.player2.y = self.player2.y + speedY*dt
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
				end
				
			elseif event.type == 'disconnect' then
				state.switch(menu, 'clientDisconnect')
			end
		end
	end
	
	
	if self.state == 'run' then
		self.lastSendTimer = self.lastSendTimer + dt
		dx, dy = self.player:update(dt)
		
		if dx ~= 0 or dy ~= 0 then
			if self.lastSendTimer > .1 then
				self.lastSendTimer = 0
				self:sendMove()
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
end

function game:draw()
    love.graphics.setFont(font[48])
	
	self.player:draw()
	self.player2:draw()
	
	
	love.graphics.setFont(fontBold[16])
	
	love.graphics.setColor(255, 255, 255)
	love.graphics.print(love.timer.getFPS()..'FPS', 5, 5)
	
	
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


function game:sendMove(x, y)
	local x, y = self.player.x, self.player.y
	if self.hosting then
		self.host:broadcast('p|'..self.timer..' '..x..' '..y)
	elseif self.peer then
		self.peer:send('p|'..self.timer..' '..x..' '..y)
	end
end