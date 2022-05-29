Dim Shared As KeyboardKey MovKeys(0 To 3) => { KEY_D, KEY_S, KEY_A, KEY_W }

Type UySun
    Public:
        Declare Constructor()
        Declare Constructor(TexturePath As String, BulletPath As String, Pos As Vector2, Speed As Single)
        Declare Function OutOfBounds(NewX As Single, NewY As Single) As Boolean
        Declare Sub UpdateBullet(Df As Single, BossBody As Circle, ByRef BossHp As Integer)
        Declare Sub Movement(Df As Single)
        Declare Sub Update(Df As Single)
        Declare Sub Draw()
        Declare Sub Unload()
        Declare Sub Reset()

        Texture As Texture2D
        BulletTexture As Texture2D
        Body As Circle
        Position As Vector2
        Center As Vector2
        Speed As Single
        DefaultSpeed As Single
        ShootTimer As Single
        MaxShootTimer As Single = 0.2
        ActiveBullets As Integer
        Health As Integer
        GotHit As Boolean
        GameOver As Boolean
        HitTimer As Single
        MaxHitTimer As Single
        TextureSize As Vector2
        BulletList(0 To 999) As Bullet
End Type

Constructor UySun()
End Constructor

Constructor UySun(TexturePath As String, BulletPath As String, Pos As Vector2, Speed As Single)
    This.Texture = LoadTexture(TexturePath)
    This.BulletTexture = LoadTexture(BulletPath)
    This.TextureSize = Vector2(This.Texture.width, This.Texture.height)
    This.Body = Circle(Vector2(Pos.x + This.Texture.width\2, Pos.y + This.Texture.height\2), 20)
    This.Position = Pos
    This.Speed = Speed
    This.DefaultSpeed = Speed
    This.ActiveBullets = 0
    This.Health = 3
    This.ShootTimer = 0.0
    This.GotHit = False
    This.GameOver = False
    This.HitTimer = 0.0
    This.MaxHitTimer = 0.3
End Constructor

Sub UySun.Unload()
    UnloadTexture(This.Texture)
    UnloadTexture(tHIS.BulletTexture)
End Sub

Sub UySun.Reset()
    This.Position = Vector2(230, 400)
    This.Body.Position = Vector2(230, 400)
    This.ShootTimer = This.MaxShootTimer
    This.ActiveBullets = 0
    This.GotHit = False
    This.GameOver = False
    This.HitTimer = 0.0
    This.Health = 3
    This.TextureSize = Vector2(This.Texture.width, This.Texture.height)

    For I As Integer = 0 To 999
        This.BulletList(I).Active = False
    Next
End Sub

Function UySun.OutOfBounds(NewX As Single, NewY As Single) As Boolean
    Dim As Single RightSide = NewX + This.Texture.width
    Dim As Single Bottom = NewY + This.Texture.height
    If (NewX < 0 Or RightSide > GetScreenWidth() Or NewY < 0 Or Bottom > GetScreenHeight()) Then
        Return True
    End If
    Return False
End Function

Sub UySun.UpdateBullet(Df As Single, BossBody As Circle, ByRef BossHp As Integer)
    If (This.ShootTimer > 0) Then
        This.ShootTimer = This.ShootTimer - Df
    End If
    If (IsKeyDown(KEY_SPACE) And CBool(This.ShootTimer <= 0) And Not This.GameOver) Then
        For I As Integer = 0 To 999
            If (Not This.BulletList(I).Active) Then
                This.BulletList(I) = Bullet( _
                    This.Center, 300.0, 300.0, 0.0, -PI/2, _
                    Rectangle(This.Center.x\2 + 30, This.Center.y, 5, 40), _
                    Rectangle(0, 0, This.BulletTexture.width, This.BulletTexture.height) _
                )
                This.BulletList(I).Active = True
                This.ActiveBullets = This.ActiveBullets + 1
                This.ShootTimer = This.MaxShootTimer
                Exit For
            End If
        Next
    End If
    For I As Integer = 999 To 0 Step -1
        If (Not This.BulletList(I).Active) Then
            Continue For
        End If
        Dim As Single x = This.BulletList(I).Position.x
        Dim As Single y = This.BulletList(I).Position.y
        x = x + This.BulletList(I).Speed * Cos(This.BulletList(I).Angle) * Df
        y = y + This.BulletList(I).Speed * Sin(This.BulletList(I).Angle) * Df
        '' Check collision
        If (CheckCollisionCircleRec(BossBody.Position, BossBody.Radius, This.BulletList(I).Hitbox)) Then
            This.BulletList(I).Active = False
            This.ActiveBullets = This.ActiveBullets - 1
            BossHp -= 1
            Continue For
        End If

        If (This.BulletList(I).IsOffscreen(x, y)) Then
            This.BulletList(I).Active = False
            This.ActiveBullets = This.ActiveBullets - 1
            Continue For
        End If
        This.BulletList(I).SetPosition(x, y)
        This.BulletList(I).Hitbox.x = x-8
        This.BulletList(I).Hitbox.y = y
    Next
End Sub

Sub UySun.Movement(Df As Single)
    Dim As Single Angle = 0.0
    Dim As Integer KeyCount = 0
    Dim As Integer KeyIndex = -1
    For I As Integer = 0 To 3
        If (IsKeyDown(MovKeys(I))) Then
            If (KeyCount = 0) Then
                Angle = I * PI/2
                KeyCount = KeyCount + 1
                KeyIndex = I
            ElseIf (KeyCount = 1) Then
                Dim As Single NewAngle = I * PI/2
                Dim As Single BiggestAngle = IIf(NewAngle > Angle, NewAngle, Angle)
                If (Abs(I - KeyIndex) = 1) Then
                    Angle = BiggestAngle - Abs(NewAngle - Angle) / 2
                ElseIf (Abs(I - KeyIndex) = 3) Then
                    Angle = -PI/4
                End If
            End If
        End If
    Next

    If (IsKeyDown(KEY_LEFT_SHIFT) Or IsKeyDown(KEY_RIGHT_SHIFT)) Then
        This.Speed = This.DefaultSpeed - 100
    Else
        This.Speed = This.DefaultSpeed
    End If

    If (KeyCount > 0) Then
        Dim As Single Df = IIf(GetFrameTime() > 1/60, 1/60, GetFrameTime())
        Dim As Single Dx = This.Speed * Cos(Angle) * Df
        Dim As Single Dy = This.Speed * Sin(Angle) * Df
        Dim As Single NewX = This.Position.x + Dx
        Dim As Single NewY = This.Position.y + Dy
        '' Check collision here
        If (Not This.OutOfBounds(NewX, NewY)) Then
            This.Position.x = NewX
            This.Position.y = NewY
        End If
    End If
End Sub

Sub UySun.Update(Df As Single)
    If (This.Health <= 0) Then
        This.GameOver = True
    End If
    If (This.GameOver) Then
        If (This.TextureSize.x > 0 Or This.TextureSize.y > 0) Then
            This.TextureSize.x -= 50*Df
            This.TextureSize.y -= 50*Df
        End If
        Return
    End If
    This.Movement(Df)
    This.Center = Vector2( _
        This.Position.x + This.Texture.width\2, This.Position.y + This.Texture.height\2 _
    )
    This.Body.Position = This.Center
    If (This.GotHit And This.HitTimer <= 0) Then
        This.HitTimer = This.MaxHitTimer
    End If
    This.HitTimer = IIf(This.HitTimer > 0, This.HitTimer-Df, 0.0)
    This.GotHit = CBool(This.HitTimer > 0.0)
End Sub

Sub UySun.Draw()
    For I As Integer = 0 To 999
        If (Not This.BulletList(I).Active) Then
            Continue For
        End If
        This.BulletList(I).Draw(This.BulletTexture)
    Next
    Dim As Color SunColor = IIf(This.GotHit, RED, WHITE)
    DrawTexturePro( _
        This.Texture, _
        Rectangle(0, 0, This.Texture.width, This.Texture.height), _
        Rectangle(This.Position.x, This.Position.y, This.TextureSize.x, This.TextureSize.y), _
        Vector2(0, 0), _
        0.0, _
        SunColor _
    )
    For I As Integer = 0 To 2
        DrawRectangleRec(Rectangle(17 + (I*25), GetScreenHeight()-13, 26, 16), BLACK)
        If (This.Health > I) Then
            DrawRectangleRec(Rectangle(20 + I*25, GetScreenHeight()-10, 20, 10), GREEN)
        End If
    Next
    #ifdef DEBUG
    DrawCircleV(This.Body.Position, This.Body.Radius, Color(55, 0, 0, 120))
    #endif
End Sub