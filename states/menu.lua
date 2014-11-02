menu = {}

function menu:enter(prev, disconnect)
    self.hosting = false
	self.disconnected = nil
	
	if disconnect == 'hostDisconnect' then
		self.disconnected = 'host'
	elseif disconnect == 'clientDisconnect' then
		self.disconnected = 'client'
	end
end

function menu:update(dt)

end

function menu:keyreleased(key, code)
    if key == 'return' then
        state.switch(game, self.hosting)
    end
end

function menu:keypressed(key, isrepeat)
	if key == '1' then
		if self.hosting then
			self.hosting = false
		else
			self.hosting = true
		end
	end
end

function menu:mousepressed(x, y, button)
	-- gets past menu on android
	--state.switch(game, self.hosting)
end

function menu:draw()
	love.graphics.setColor(255, 255, 255)
    local text = "> ENTER <"
    local x = love.window.getWidth()/2 - fontBold[48]:getWidth(text)/2
    local y = love.window.getHeight()/2
    love.graphics.setFont(fontBold[48])
    love.graphics.print(text, x, y)
	
	if self.hosting then
		love.graphics.print('You are hosting', 5, 5)
	end
	
	love.graphics.setColor(255, 0, 0)
	if self.disconnected == 'host' then
		love.graphics.print('The client disconnected.', 5, 60)
	elseif self.disconnected == 'client' then
		love.graphics.print('The host disconnected.', 5, 60)
	end
end