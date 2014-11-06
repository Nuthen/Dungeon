Enemy = class('Enemy')

function Enemy:initialize(x, y)
	local scrnWidth, scrnHeight = love.graphics.getDimensions()
	local side = math.random(1, 2)
	self.x = x or side == 1 and 0 or side == 2 and scrnWidth
	self.y = y or math.random(scrnHeight)
	
	self.width = 40
	self.height = 40
	
	self.speed = 50
	
	self.color = {255, 0, 0}
	
	self.tween = false
	
	self.packets = {}
	
	self.hit = false
end

function Enemy:hostUpdate(dt)
	if not self.hit then
		local player1 = game.player
		local player2 = game.player2
		
		if math.dist(self.x, self.y, player1.x, player1.y) < math.dist(self.x, self.y, player2.x, player2.y) then
			self:moveTowards(player1.x, player1.y, self.speed*dt)
		else
			self:moveTowards(player2.x, player2.y, self.speed*dt)
		end
	end
end

function Enemy:clientUpdate()
	if not self.hit then
		if #self.packets > 0 then
			local packet = self.packets[1]
			local timeSent = packet[1]
			local x = packet[2]
			local y = packet[3]
			
			if not self.tween then
				local timeLeft = math.abs(game.timer-game.timerDelay - timeSent)
				--error(timeLeft)
				-- the .5 is a cheap fix but it works
				-- the time should be the same as the server's enemySendInterval
				tween(1, self, {x = x, y = y}, 'linear', function()
					self.tween = false
				end)
				self.tween = true
				
				table.remove(self.packets, 1)
			end
		end
	end
end

function Enemy:draw()
	if not self.hit then
		love.graphics.setColor(self.color)
		love.graphics.rectangle('fill', self.x-self.width/2, self.y-self.height/2, self.width, self.height)
	end
end


function Enemy:moveTowards(x, y, speed)
	local angle = math.angle(self.x, self.y, x, y)
	
	local dx = math.cos(angle) * speed
	local dy = math.sin(angle) * speed
	
	self.x = self.x + dx
	self.y = self.y + dy
end

function Enemy:storePacket(timeSent, x, y)
	table.insert(self.packets, {timeSent, x, y})
end