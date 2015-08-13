Random = {
    init = function(seed)
        local new = {
            seed = 0
        }
        setmetatable(new, {__index = Random})
        new:reseed(seed)
        return new
    end,

    next_int = function(self)
        local s0 = self.seed
        self.seed = bit32.bxor(self.seed, bit32.lshift(self.seed,13))
        self.seed = bit32.bxor(self.seed, bit32.rshift(self.seed,17))
        self.seed = bit32.bxor(self.seed, bit32.lshift(self.seed,5))
        return bit32.extract(self.seed + s0, 0, 32)
    end,

    randint = function(self, ...)
        local arg = {...}
        if #arg == 0 then
            return self:next_int()
        elseif #arg == 1 then
            l, u = 0, math.floor(arg[1])
        else
            l, u = math.ceil(arg[1]), math.floor(arg[2])
        end
        if l>u then
            error("Random::randint(): 1st argument is greater than 2nd")
        end
        local nbins = u + 1 - l;
        local nrand = 4294967296
        local bin_size = math.floor(nrand/nbins)
        local defect = math.floor(nrand%nbins)
        local x = self:next_int()
        while nrand - defect <= x do
            x = self:next_int()
        end
        return l + math.floor(x/bin_size);
    end,

    random = function(self, ...)
        local arg = {...}
        if #arg == 0 then
            l, u = 0, 1
        elseif #arg == 1 then
            l, u = 0, arg[1]
        else
            l, u = arg[1], arg[2]
        end
        local r = (1/4294967295) * self:next_int()
        return l + r * ( u - l );
    end,

    reseed = function(self, seed)
        self.seed = seed
        for i = 1,5 do
            self:next_int()
        end
    end
}
