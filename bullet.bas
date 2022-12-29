Type Bullet
    Public:
        Declare Constructor()
        Declare Constructor(Position As Vector2, Speed As Single, MaxSpeed As Single, Acc As Single, Angle As Single, Hitbox As Rectangle, Origin As Rectangle)

        Declare Function IsOffscreen(x As Integer, y As Integer) As Boolean
        Declare Sub SetPosition(NewX As Integer, NewY As Integer)
        Declare Sub Draw(Texture As Texture2D)
        Position As Vector2
        Speed As Single
        MaxSpeed As Single
        Acc As Single
        Angle As Single
        Origin As Rectangle
        Hitbox As Rectangle
        Active As Boolean = False
End Type

Constructor Bullet()
End Constructor

Constructor Bullet(Position As Vector2, Speed As Single, MaxSpeed As Single, Acc As Single, Angle As Single, Hitbox As Rectangle, Origin As Rectangle)
    This.Active = True
    This.Position = Position
    This.Speed = Speed
    This.MaxSpeed = MaxSpeed
    This.Acc = Acc
    This.Angle = Angle
    This.Hitbox = Hitbox
    This.Origin = Origin
End Constructor

Function Bullet.IsOffscreen(x As Integer, y As Integer) As Boolean
    If (x > GetScreenWidth()+50 Or x < -50 Or y > GetScreenHeight()+50 Or y < -50) Then
        Return True
    End If
    Return False
End Function

Sub Bullet.SetPosition(NewX As Integer, NewY As Integer)
    This.Position.x = NewX
    This.Position.y = NewY
    This.Hitbox.x = NewX
    This.Hitbox.y = NewY
End Sub

Sub Bullet.Draw(Texture As Texture2D)
    DrawTexturePro( _
        Texture, _
        This.Origin, _
        Rectangle(This.Position.x, This.Position.y, Texture.width_\2, Texture.height_\2), _ 
        Vector2(Texture.width_\2, Texture.height_\2), _ 
        This.Angle * RAD2DEG, _
        WHITE _
    )
    #ifdef DEBUG
    DrawRectangleRec(This.Hitbox, BLACK)
    #endif
End Sub