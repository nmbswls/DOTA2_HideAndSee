function CTestGameMode:Rotate(nPlayerId, nAngle)

	CustomGameEventManager:Send_ServerToPlayer(PlayerResouce:GetPlayer(nPlayerId),
		"CameraRotate",
		{angle = nAngle})

	
end

function CTestGameMode:On_ed_player_start_move_up(keys)
    local player = PlayerResource:GetPlayer(keys.PlayerID)
    
end