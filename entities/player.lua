Player = class('Player')

function Player:initialize(x, y)
	self.x = x
	self.y = y
	
	self.width = 64
	self.height = 64
	
	self.color = {math.random(255), math.random(255), math.random(255)}
	
	self.speed = 150
end

function Player:update(dt)

	local dx, dy = 0, 0
	if love.keyboard.isDown('w') then
		dy = -self.speed*dt
	elseif love.keyboard.isDown('s') then
		dy = self.speed*dt
	end
	
	if love.keyboard.isDown('a') then
		dx = -self.speed*dt
	elseif love.keyboard.isDown('d') then
		dx = self.speed*dt
	end
	
	self.x = self.x + dx
	self.y = self.y + dy
	
	return dx, dy
end

function Player:draw()
	love.graphics.setColor(self.color)
	love.graphics.rectangle('fill', self.x - self.width/2, self.y - self.height/2, self.width, self.height)
end