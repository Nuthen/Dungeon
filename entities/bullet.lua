Bullet = class('Bullet')

function Bullet:initialize(x, y, targetX, targetY)
	self.x = x
	self.y = y
	self.angle = math.atan2(targetY - y, targetX - x)

	self.speed = 550
	self.radius = 5
	
	self.destroy = false
end

function Bullet:update(dt)
    self.x = self.x + self.speed * math.cos(self.angle)*dt
	self.y = self.y + self.speed * math.sin(self.angle)*dt

	if self.x < -self.radius or self.x > love.window.getWidth()+self.radius then
		self.destroy = true
	end

	if self.y < -self.radius or self.y > love.window.getHeight()+self.radius then
		self.destroy = true
	end
end

function Bullet:draw()
    love.graphics.setColor(255, 255, 255)
	love.graphics.circle('fill', self.x, self.y, self.radius)
end


function Bullet:checkHit()
	for i, enemy in ipairs(game.enemies) do
		if not enemy.hit then
			if self.x + self.radius >= enemy.x - enemy.width/2 and self.x - self.radius <= enemy.x + enemy.width/2 and self.y + self.radius >= enemy.y - enemy.height/2 and self.y - self.radius <= enemy.y + enemy.height/2 then
				-- hit
				enemy.hit = true
				
				game:sendEnemyHit(i)
				self.destroy = true
				break
			end
		end
	end
end