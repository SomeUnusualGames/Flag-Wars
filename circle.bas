Type Circle
    Public:
        Declare Constructor()
        Declare Constructor(Position As Vector2, Radius As Integer)

        Position As Vector2
        Radius As Integer
End Type

Constructor Circle()
End Constructor

Constructor Circle(Position As Vector2, Radius As Integer)
    This.Position = Position
    This.Radius = Radius
End Constructor