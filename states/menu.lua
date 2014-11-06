menu = {}

function menu:enter(prev, disconnect)
    self.hosting = false
	self.disconnected = nil
	
	if disconnect == 'hostDisconnect' then
		self.disconnected = 'host'
	elseif disconnect == 'clientDisconnect' then
		self.disconnected = 'client'
	end

    self.address = "localhost"
    love.keyboard.setKeyRepeat(true)
end

function menu:update(dt)

end

function menu:keyreleased(key, code)

end

function menu:keypressed(key, isrepeat)
	if key == 'h' then
		self.hosting = not self.hosting
	end

    if not self.hosting then
        if key == '1' then
            self.address = "69.137.215.69"
        elseif key == '2' then
            self.address = "98.235.73.162"
        elseif key == '3' then
            self.address = "localhost"
        end

        if key == "1" or key == "2" or key == "3" then
            state.switch(game, self.hosting, self.address)
        end
    else
        if key == "1" then
            state.switch(game, self.hosting, self.address)
        end
    end

    if key == "backspace" then
        self.address = string.sub(self.address, 1, -2)
    end
end

function menu:mousepressed(x, y, button)
	-- gets past menu on android
	--state.switch(game, self.hosting, self.address)
end


function menu:draw()
    love.graphics.setColor(255, 255, 255)

    local text = "[H] Toggle hosting"
    local x = love.window.getWidth()/2 - font[36]:getWidth(text)/2
    local y = love.window.getHeight()/2 - 75
    love.graphics.setFont(font[36])
    love.graphics.print(text, x, y)

    if not self.hosting then
        local text = "[1] Connect to Nuthen"
        local x = love.window.getWidth()/2 - font[36]:getWidth(text)/2
        local y = love.window.getHeight()/2
        love.graphics.setFont(font[36])
        love.graphics.print(text, x, y)

        local text = "[2] Connect to Ikroth"
        local x = love.window.getWidth()/2 - font[36]:getWidth(text)/2
        local y = love.window.getHeight()/2 + 50
        love.graphics.setFont(font[36])
        love.graphics.print(text, x, y)

        local text = "[3] Connect to localhost"
        local x = love.window.getWidth()/2 - font[36]:getWidth(text)/2
        local y = love.window.getHeight()/2 + 100
        love.graphics.setFont(font[36])
        love.graphics.print(text, x, y)
    end
	
	if self.hosting then
		local text = "HOSTING"
        local x = love.window.getWidth()/2 - fontBold[72]:getWidth(text)/2
        local y = love.window.getHeight()/2 - 250
        love.graphics.setFont(fontBold[72])
        love.graphics.print(text, x, y)

        local text = "[1] Start server"
        local x = love.window.getWidth()/2 - font[36]:getWidth(text)/2
        local y = love.window.getHeight()/2
        love.graphics.setFont(font[36])
        love.graphics.print(text, x, y)
	end
	
	love.graphics.setColor(255, 0, 0)
	if self.disconnected == 'host' then
		love.graphics.print('The client disconnected.', 5, 60)
	elseif self.disconnected == 'client' then
		love.graphics.print('The host disconnected.', 5, 60)
	end
end