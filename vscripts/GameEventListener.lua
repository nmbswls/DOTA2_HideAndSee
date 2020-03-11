function CTestGameMode:_RegisterCustomGameEventListeners()
    -- 移动相关
    -- CustomGameEventManager:RegisterListener("ed_player_start_move_up", function(_, keys)
    --     self:On_ed_player_start_move_up(keys)
    -- end)
    
    --鼠标的事件
    CustomGameEventManager:RegisterListener("eum", function(_, keys)
        self:On_ed_player_update_mouse_position(keys)
    end)
    
    CustomGameEventManager:RegisterListener("erd", function(_, keys)
        self:On_ed_player_right_mouse_down(keys)
    end)
    -- CustomGameEventManager:RegisterListener("eru", function(_, keys)
    --     self:On_ed_player_right_mouse_up(keys)
    -- end)
end


function CTestGameMode:On_ed_player_update_mouse_position(keys)
    local player = PlayerResource:GetPlayer(keys.PlayerID)
    --print(keys.x .. " " .. keys.y .. " " .. keys.z);
    if not player then
        return
    end
    local hero = player:GetAssignedHero()
    if not hero then
        return
    end
    
    hero.m_MousePosition = Vector(keys.x, keys.y, keys.z)
end



function CTestGameMode:On_ed_player_right_mouse_down(keys)
    print("get msgs mouse down");
    local player = PlayerResource:GetPlayer(keys.PlayerID)
    if not player then
        return
    end
    local hero = player:GetAssignedHero()
    if not hero then
        return
    end

    hero.bRightMouseDown = true;
    --print(hero.m_MousePosition);
    if hero.unit and hero.unit:IsAlive() then
        if hero.m_MousePosition then
            hero.unit:MoveToPosition(hero.m_MousePosition);
        end
    end
end




