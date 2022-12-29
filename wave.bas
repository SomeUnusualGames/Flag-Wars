Type BossWave
    Public:
        Declare Constructor()
        Declare Constructor(SunRegion As Rectangle, Mov As Single, WaveTimer As Single, ShootTimer As Single)
        SunRegion As Rectangle
        MovTimer As Single
        CurrentMovTimer As Single
        WaveTimer As Single
        CurrentWaveTimer As Single
        ShootTimer As Single
        CurrentShootTimer As Single
End Type

Constructor BossWave()
End Constructor

Constructor BossWave(SunRegion As Rectangle, Mov As Single, WaveTimer As Single, ShootTimer As Single)
    This.SunRegion = SunRegion
    This.MovTimer = Mov
    This.CurrentMovTimer = Mov
    This.WaveTimer = WaveTimer
    This.CurrentWaveTimer = WaveTimer
    This.ShootTimer = ShootTimer
    This.CurrentShootTimer = ShootTimer
End Constructor

