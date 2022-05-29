#include "wave.bas"

#define RAYCOUNT 32
#define MAX_BULLETS 999
#define RANDOM_SIZE(size) ((GetRandomValue(0, 100) > 50) * (size))
#define LERP(a, b, t) ((a) + ((b) - (a)) * (t))

#macro NEW_BULLET(BulletList, Pos, Speed, MaxSpeed, Acc, Angle, Hitbox, Origin)
    For I As Integer = 0 To MAX_BULLETS
        If (Not BulletList(I).Active) Then
            BulletList(I) = Bullet(Pos, Speed, MaxSpeed, Acc, Angle, Hitbox, Origin)
            BulletList(I).Active = True
            Exit For
        End If
    Next
#endmacro

Enum EyeType
    Left = 0
    Right
End Enum

'' ---------- SunRay Type ----------
Type SunRay
    Public:
        Declare Constructor()
        Declare Constructor(Texture As Texture2D, Pos As Vector2, Origin As Rectangle, Ang As Single)

        Texture As Texture2D
        Position As Vector2
        Origin As Rectangle
        Angle As Single
        Show As Boolean
End Type

Constructor SunRay()
End Constructor

Constructor SunRay(Texture As Texture2D, Pos As Vector2, Origin As Rectangle, Ang As Single)
    This.Texture = Texture
    This.Position = Pos
    This.Origin = Origin
    This.Angle = Ang
    This.Show = True
End Constructor
'' ---------- SunRay Type End ----------

'' ---------- Eye Type ----------
Type Eye
    Public:
        Declare Constructor()
        Declare Sub LookAt(Position As Vector2)
        Declare Sub Movement(NewPos As Vector2)

        Texture As Texture2D
        EyeLocation As EyeType
        Rect As Rectangle
        TrackPlayer As Boolean
        Center As Vector2
End Type

Constructor Eye()
End Constructor

Sub Eye.LookAt(Position As Vector2)
    If (Not This.TrackPlayer) Then
        Return
    End If
    Dim As Single Angle = ATan2(Position.y - This.Rect.y, Position.x - This.Rect.x)
    This.Rect.x = This.Center.x + 3 * Cos(Angle)
    This.Rect.y = This.Center.y + 2 * Sin(Angle)
End Sub

Sub Eye.Movement(NewPos As Vector2)
    Dim As Integer XOffset = IIf(This.EyeLocation = EyeType.Left, 32, 64)
    This.Center = Vector2(NewPos.x + XOffset, NewPos.y + 41)
    This.Rect = Rectangle(_
        NewPos.x + XOffset, NewPos.y + 41, _
        This.Texture.width, This.Texture.height _
    )
End Sub
'' ---------- Eye Type End ----------

Type ArSun
    Public:
        Declare Constructor()
        Declare Constructor(SunTexture As String, RayTexture As String, EyeTexture As String, Pos As Vector2)
        Declare Sub Unload()
        Declare Sub LoadWaves()
        Declare Sub RotateRays(Df As Single)
        Declare Sub CenterEyes()
        Declare Sub LookAt(Pos As Vector2)
        Declare Sub Movement(Df As Single)
        Declare Sub CreateBullet()
        Declare Sub Update(Df As Single, PlayerBody As Circle, ByRef PlayerHp As Integer, ByRef PlayerHit As Boolean)
        Declare Sub Reset()
        Declare Sub Draw()
        Declare Sub DrawHealth()

        Texture As Texture2D
        Position As Vector2
        PlayerPosition As Vector2
        Body As Circle
        TargetPosition As Vector2
        RayTexture As Texture2D
        LeftEye As Eye
        RightEye As Eye
        IsRotating As Boolean
        RayRotationSpeed As Single
        Health As Integer
        MaxHealth As Integer
        ShootTimer As Single
        MaxShootTimer As Single
        BulletAngle As Single
        TextureSize As Vector2
        BulletList(0 To MAX_BULLETS) As Bullet
        Rays(0 To RAYCOUNT-1) As SunRay
        StageWaves(0 To 5) As BossWave
        CurrentStage As Integer = 0
        CurrentWave As Integer = 0
End Type

Constructor ArSun()
End Constructor

Constructor ArSun(SunTexture As String, RayTexture As String, EyeTexture As String, Pos As Vector2)
    This.Texture = LoadTexture(SunTexture)
    This.Position = Pos
    This.TargetPosition = Pos
    This.Body = Circle( _
        Vector2(Pos.x + This.Texture.width\2, Pos.y + This.Texture.height\2), _
        50 _
    )
    This.RayRotationSpeed = 1.0
    This.MaxHealth = 900
    This.Health = This.MaxHealth
    This.BulletAngle = 0.0
    This.TextureSize = Vector2(This.Texture.width, This.Texture.height)

    '' Eyes
    This.LeftEye.Texture = LoadTexture(EyeTexture)
    This.LeftEye.TrackPlayer = True
    This.LeftEye.EyeLocation = EyeType.Left
    This.LeftEye.Center = Vector2(This.Position.x + 32, This.Position.y + 41)
    This.LeftEye.Rect = Rectangle(_
        This.Position.x + 32, This.Position.y + 41, _
        This.LeftEye.Texture.width, This.LeftEye.Texture.height _
    )

    This.RightEye.Texture = LoadTexture(EyeTexture)
    This.RightEye.TrackPlayer = True
    This.RightEye.EyeLocation = EyeType.Right
    This.RightEye.Center = Vector2(This.Position.x + 64, This.Position.y + 41)
    This.RightEye.Rect = Rectangle( _
        This.Position.x + 64, This.Position.y + 41, _
        This.RightEye.Texture.width, This.RightEye.Texture.height _
    )

    '' Rays
    This.RayTexture = LoadTexture(RayTexture)
    This.IsRotating = True
    For I As Integer = 0 To RAYCOUNT - 1
        Dim As Single Ang = I * (1/16) * PI '' I * 11.25º
        Dim As Vector2 Pos = Vector2(_
            This.Position.x + This.Texture.width \ 2 + 83 * Cos(Ang), _
            This.Position.y + This.Texture.height \ 2 + 82 * Sin(Ang) _
        )
        Dim As Rectangle OriginRect
        If (I Mod 2 = 0) Then
            OriginRect = Rectangle(0, 0, 72, 10)
        Else
            OriginRect = Rectangle(0, 10, 72, 13)
        End If
        This.Rays(i) = SunRay(This.RayTexture, Pos, OriginRect, Ang)
    Next
    This.LoadWaves()
End Constructor

Sub ArSun.Unload()
    UnloadTexture(This.Texture)
    UnloadTexture(This.RayTexture)
    UnloadTexture(This.LeftEye.Texture)
    UnloadTexture(This.RightEye.Texture)
End Sub

Sub ArSun.LoadWaves()
    Dim As Const Integer W = GetScreenWidth()
    Dim As Const Integer H = GetScreenHeight()
    For I As Integer = 0 To 5
        '' Case 0 values
        Dim As Rectangle SunRegion = Rectangle(100, 50, W-200, (H\2) - 200)
        Dim As Single ShootTimer = 1.0
        Select Case As Const I
            Case 1
                SunRegion = Rectangle(300, 50, W-600, (H\2) - 200)
                ShootTimer = 0.1
            Case 2
                SunRegion = Rectangle(300, 50, W-600, (H\2) - 200)
            Case 3
                SunRegion = Rectangle(100, 50, W-200, H-200)
                ShootTimer = 0.08
            Case 4
                SunRegion = Rectangle((W\2)-10, (H\2)-20, 20, 20)
                ShootTimer = 0.08
            Case 5
                SunRegion = Rectangle((W\2)-10, (H\2)-200, 20, 20)
                ShootTimer = 0.08
        End Select
        This.StageWaves(I) = BossWave(SunRegion, 6.0, 30.0, ShootTimer)
    Next    
End Sub

Sub ArSun.RotateRays(Df As Single)
    If (Not This.IsRotating) Then
        Return
    End If
    For I As Integer = 0 To RAYCOUNT - 1
        This.Rays(i).Angle = This.Rays(i).Angle + This.RayRotationSpeed * Df
        If (This.Rays(i).Angle >= 2*PI) Then
            This.Rays(i).Angle = This.Rays(i).Angle - 2*PI
        End If
        This.Rays(i).Position.x = This.Position.x + This.Texture.width \ 2 + 83 * Cos(This.Rays(i).Angle)
        This.Rays(i).Position.y = This.Position.y + This.Texture.height \ 2 + 82 * Sin(This.Rays(i).Angle)
    Next
End Sub

Sub ArSun.CenterEyes()
    This.LeftEye.Rect.x = This.LeftEye.Center.x
    This.LeftEye.Rect.y = This.LeftEye.Center.y
    This.RightEye.Rect.x = This.RightEye.Center.x
    This.RightEye.Rect.y = This.RightEye.Center.y
End Sub

Sub ArSun.LookAt(Pos As Vector2)
    This.LeftEye.LookAt(Pos)
    This.RightEye.LookAt(Pos)
End Sub

Sub ArSun.Movement(Df As Single)
    Dim As Boolean UpdateEye = False
    If (Abs(This.Position.x - This.TargetPosition.x) > 30) Then
        This.Position.x = LERP(This.Position.x, This.TargetPosition.x, 0.01)
        UpdateEye = True
    End If
    If (Abs(This.Position.y - This.TargetPosition.y) > 30) Then
        This.Position.y = LERP(This.Position.y, This.TargetPosition.y, 0.01)
        UpdateEye = True
    End If
    If (UpdateEye) Then
        This.LeftEye.Movement(This.Position)
        This.RightEye.Movement(This.Position)
    End If
End Sub

Sub ArSun.CreateBullet()
    Dim As Integer CurrentWave = This.CurrentWave + (3 * This.CurrentStage)
    Select Case As Const CurrentWave
    Case 0
        For N As Integer = 0 To RAYCOUNT\2
            NEW_BULLET( _
                This.BulletList, This.Body.Position, _
                250.0, 250.0, 0.0, N * (1/8) * PI, _
                Rectangle(This.Body.Position.x, This.Body.Position.y, 5, 5), _
                Rectangle(0, RANDOM_SIZE(11), This.RayTexture.width, 11) _
            )
        Next
    Case 1
        NEW_BULLET(_ 
            This.BulletList, This.Body.Position, _
            250.0, 250.0, 0.0, This.BulletAngle * DEG2RAD, _
            Rectangle(This.Body.Position.x, This.Body.Position.y, 5, 5), _
            Rectangle(0, RANDOM_SIZE(11), This.RayTexture.width, 11) _
        )
    Case 2
        For N As Integer = 0 To RAYCOUNT
            NEW_BULLET( _
                This.BulletList, This.Body.Position, _
                250.0, 50.0, -1.0, N * (1/8) * PI, _
                Rectangle(This.Body.Position.x, This.Body.Position.y, 5, 5), _
                Rectangle(0, RANDOM_SIZE(11), This.RayTexture.width, 11) _
            )
        Next
    Case 3
        Dim As Single Angle = ATan2( _
            This.Body.Position.y - This.PlayerPosition.y, _
            This.Body.Position.x - This.PlayerPosition.x _
        )
        For N As Integer = 0 To 1
            NEW_BULLET( _
                This.BulletList, This.Body.Position, _
                250.0, 250.0, 0.0, Angle - (N * PI), _
                Rectangle(This.Body.Position.x, This.Body.Position.y, 5, 5), _
                Rectangle(0, RANDOM_SIZE(11), This.RayTexture.width, 11) _
            )
        Next
    Case 4, 5
        Dim As Single CurrentSpeed = IIf(CurrentWave = 4, 200.0, 150.0)
        Dim As Single CurrentAcc = IIf(CurrentWave = 4, 0.0, -1.0)
        For N As Integer = 0 To 7
            If (GetRandomValue(0, 100) < 40) Then
                Continue For
            End If
            NEW_BULLET( _
                This.BulletList, This.Body.Position, _
                CurrentSpeed, -200.0, CurrentAcc, This.BulletAngle + (N * PI/4) + (DEG2RAD * GetRandomValue(45, 360)), _
                Rectangle(This.Body.Position.x, This.Body.Position.y, 5, 5), _
                Rectangle(0, RANDOM_SIZE(11), This.RayTexture.width, 11) _
            )
        Next
    End Select
End Sub

Sub ArSun.Update(Df As Single, PlayerBody As Circle, ByRef PlayerHp As Integer, ByRef PlayerHit As Boolean)
    Dim As Const Integer WaveIndex = This.CurrentWave + (3 * This.CurrentStage)
    Dim As BossWave Pointer CurrentWave = @This.StageWaves(WaveIndex)

    If (This.Health <= 0) Then
        If (This.TextureSize.x > 0 Or This.TextureSize.y > 0) Then
            This.TextureSize.x -= 50*Df
            This.TextureSize.y -= 50*Df
        Else
            Return
        End If

        For I As Integer = 0 To RAYCOUNT
            This.Rays(I).Show = False
        Next
        For I As Integer = 0 To 999
            This.BulletList(I).Active = False
        Next
        Return
    End If

    This.Body.Position.x = This.Position.x + (This.Texture.width \ 2)
    This.Body.Position.y = This.Position.y + (This.Texture.height \ 2)

    CurrentWave->MovTimer -= Df
    If (CurrentWave->MovTimer <= 0) Then
        Dim As Rectangle SunRegion = CurrentWave->SunRegion
        This.TargetPosition.x = GetRandomValue(SunRegion.x, SunRegion.x+SunRegion.width)
        This.TargetPosition.y = GetRandomValue(SunRegion.y, SunRegion.y+SunRegion.height)
        CurrentWave->MovTimer = CurrentWave->CurrentMovTimer
    End If

    CurrentWave->WaveTimer -= Df
    If (CurrentWave->WaveTimer <= 0) Then
        This.CurrentWave += 1
        If (This.CurrentWave = 3) Then
            This.CurrentWave = 0
        End If
        CurrentWave->WaveTimer = CurrentWave->CurrentWaveTimer
    End If

    If (WaveIndex = 1) Then
        This.BulletAngle += 2
    ElseIf (WaveIndex = 4) Then
        This.BulletAngle += Df/2
    End If

    CurrentWave->ShootTimer -= Df
    If (CurrentWave->ShootTimer <= 0) Then
        This.CreateBullet()
        CurrentWave->ShootTimer = CurrentWave->CurrentShootTimer
    End If

    For I As Integer = MAX_BULLETS To 0 Step -1
        Dim As Bullet Pointer CurrentBullet = @This.BulletList(I)
        If (Not CurrentBullet->Active) Then
            Continue For
        End If
        Dim As Single x = CurrentBullet->Position.x
        Dim As Single y = CurrentBullet->Position.y
        x = x + CurrentBullet->Speed * Cos(CurrentBullet->Angle) * Df
        y = y + CurrentBullet->Speed * Sin(CurrentBullet->Angle) * Df
        If (CurrentBullet->Acc < 0 And CurrentBullet->MaxSpeed < CurrentBullet->Speed Or _
            CurrentBullet->Acc > 0 And CurrentBullet->MaxSpeed > CurrentBullet->Speed _
        ) Then
            CurrentBullet->Speed += CurrentBullet->Acc
        End If
        '' Check collision
        If (CheckCollisionCircleRec(PlayerBody.Position, PlayerBody.Radius, CurrentBullet->Hitbox)) Then
            CurrentBullet->Active = False
            PlayerHp -= 1
            PlayerHit = True
            Continue For
        End If

        If (CurrentBullet->IsOffscreen(x, y)) Then
            CurrentBullet->Active = False
            Continue For
        End If
        CurrentBullet->SetPosition(x, y)
    Next

    If (This.Health <= 600 And This.CurrentStage = 0) Then
        This.CurrentStage = 1
        This.RayRotationSpeed += 0.5
    End If

    This.Movement(Df)
    This.RotateRays(Df)
End Sub

Sub ArSun.Reset()
    This.RayRotationSpeed = 1.0
    This.Health = This.MaxHealth
    This.BulletAngle = 0.0
    This.LeftEye.TrackPlayer = True
    This.RightEye.TrackPlayer = True
    This.CurrentStage = 0
    This.CurrentWave = 0
    This.TextureSize = Vector2(This.Texture.width, This.Texture.height)
    For I As Integer = 0 To RAYCOUNT
        This.Rays(I).Show = True
    Next

    Dim As Const Vector2 Pos = Vector2(555, 310)
    This.Position = Pos
    This.TargetPosition = Pos
    This.Body.Position = Vector2(Pos.x + This.Texture.width\2, Pos.y + This.Texture.height\2)

    This.LeftEye.Center = Vector2(Pos.x + 32, Pos.y + 41)
    This.RightEye.Center = Vector2(Pos.x + 64, Pos.y + 41)

    For I As Integer = 0 To MAX_BULLETS
        This.BulletList(I).Active = False
    Next
End Sub

Sub ArSun.Draw()
    Dim As Color CurrentColor
    Select Case As Const This.CurrentStage
        Case 0
            CurrentColor = WHITE
        Case 1
            CurrentColor = Color(75, 75, 75, 255)
        Case 2
            CurrentColor = BLACK
    End Select
    #ifdef DEBUG
    DrawRectangleRec(This.StageWaves(This.CurrentWave+(3*This.CurrentStage)).SunRegion, Color(55, 0, 0, 120))
    #endif
    '' Rays
    For I As Integer = 0 To RAYCOUNT - 1
        If (Not This.Rays(I).Show) Then
            Continue For
        End If
        DrawTexturePro( _
            This.Rays(I).Texture, _
            This.Rays(I).Origin, _
            Rectangle( _
                This.Rays(i).Position.x, This.Rays(i).Position.y, _
                This.Rays(i).Origin.width, This.Rays(i).Origin.height _
            ), _
            Vector2(This.Rays(I).Origin.width \ 2, This.Rays(i).Origin.height \ 2), _
            This.Rays(I).Angle * RAD2DEG, _
            CurrentColor _
        )
    Next

    For I As Integer = 0 To MAX_BULLETS
        If (Not This.BulletList(I).Active) Then
            Continue For
        End If
        This.BulletList(I).Draw(This.RayTexture)
    Next

    '' Body
    DrawTexturePro( _
    This.Texture, _
        Rectangle(0, 0, This.Texture.width, This.Texture.height), _
        Rectangle(This.Position.x, This.Position.y, This.TextureSize.x, This.TextureSize.y), _
        Vector2(0, 0), _
        0.0, _
        CurrentColor _
    )

    '' Eyes
    If (This.Health > 0) Then
        BeginScissorMode(This.Position.x + 26, This.Position.y + 38, 13, 7)
        DrawTexturePro( _
            This.LeftEye.Texture, _
            Rectangle(0, 0, This.LeftEye.Texture.width, This.LeftEye.Texture.height), _
            This.LeftEye.Rect, _
            Vector2(This.LeftEye.Texture.width \ 2, This.LeftEye.Texture.height \ 2), _
            0.0, _
            WHITE _
        )
        EndScissorMode()
        BeginScissorMode(This.Position.x + 58, This.Position.y + 38, 13, 7)
        DrawTexturePro( _
            This.RightEye.Texture, _
            Rectangle(0, 0, This.RightEye.Texture.width, This.RightEye.Texture.height), _
            This.RightEye.Rect, _
            Vector2(This.RightEye.Texture.width \ 2, This.RightEye.Texture.height \ 2), _
            0.0, _
            WHITE _
        )
        EndScissorMode()
    End If

    #ifdef DEBUG
    DrawCircleV(This.Body.Position, This.Body.Radius, Color(55, 0, 0, 120))
    #endif
End Sub

Sub ArSun.DrawHealth()
    DrawRectangleRec(Rectangle(0, 0, This.MaxHealth+2, 8), BLACK)
    DrawRectangleRec(Rectangle(0, 2, This.Health, 5), GREEN)
    #ifdef DEBUG
    DrawRectangleRec(Rectangle(300, 0, 5, 8), RED)
    DrawRectangleRec(Rectangle(600, 0, 5, 8), RED)
    #endif
End Sub