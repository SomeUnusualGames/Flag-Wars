#include "raylib.bi"
#include "circle.bas"
#include "bullet.bas"
#include "boss.bas"
#include "player.bas"

Type Game
    Public:
        Declare Constructor(_Width As Integer, Height As Integer, Title As String)
        Declare Destructor()

        Declare Sub InitBoss(SunTexture As String, RayTexture As String, EyeTexture As String, Pos As Vector2)
        Declare Sub InitPlayer(Texture As String, Bullet As String, Pos As Vector2, Speed As Single)
        Declare Sub CheckMusicIcon()
        Declare Sub DrawBackground()
        Declare Sub UpdateDraw()
        Declare Sub Reset()

        Boss As ArSun
        Player As UySun
        BackgroundMusic As Music
        MusicVolume As Single
        MusicIcon As Texture
        Paused As Boolean
End Type

'' Note: Width is a keyword used for the display (unrelated to raylib)
Constructor Game(_Width As Integer, Height As Integer, Title As String)
    ''SetConfigFlags(FLAG_WINDOW_RESIZABLE)
    InitWindow(_Width, Height, Title)
    InitAudioDevice()
    SetTargetFPS(60)
    This.Paused = False
    This.MusicIcon = LoadTexture("assets/graphics/harp.png")
    This.BackgroundMusic = LoadMusicStream("assets/music/Battle for Extranite.mp3")
    This.MusicVolume = 0.0
    SetMusicVolume(This.BackgroundMusic, This.MusicVolume)
    PlayMusicStream(This.BackgroundMusic)
End Constructor

Destructor Game()
    This.Boss.Unload()
    This.Player.Unload()
    UnloadTexture(This.MusicIcon)
    UnloadMusicStream(This.BackgroundMusic)
    CloseAudioDevice()
    CloseWindow()
End Destructor

Sub Game.InitBoss(SunTexture As String, RayTexture As String, EyeTexture As String, Pos As Vector2)
    This.Boss = ArSun(SunTexture, RayTexture, EyeTexture, Pos)
End Sub

Sub Game.InitPlayer(Texture As String, Bullet As String, Pos As Vector2, Speed As Single)
    This.Player = UySun(Texture, Bullet, Pos, Speed)
End Sub

Sub Game.CheckMusicIcon()
    Dim As Rectangle IconRect = Rectangle( _
        GetScreenWidth()-(This.MusicIcon.width_\2)-10, 0, _
        This.MusicIcon.width_\2, This.MusicIcon.height_ _
        )
    Dim As Boolean IconHovered = CheckCollisionPointRec(GetMousePosition(), IconRect)
    If (This.MusicVolume > 0) Then
        UpdateMusicStream(This.BackgroundMusic)
    End If
    If (IconHovered And IsMouseButtonPressed(MOUSE_BUTTON_LEFT)) Then
        This.MusicVolume = IIf(This.MusicVolume > 0, 0.0, 0.8)
        SetMusicVolume(This.BackgroundMusic, This.MusicVolume)
    End If
End Sub

Sub Game.DrawBackground()
    Dim As Integer Offset = 120
    Dim As RLColor LightBlue = RLColor(116, 172, 223, 255)
    DrawRectangleRec(Rectangle(0, 0, GetScreenWidth(), GetScreenHeight()\2 - Offset), LightBlue)
    DrawRectangleRec(Rectangle(0, GetScreenHeight()\2 + Offset, GetScreenWidth(), GetScreenHeight()\2 - Offset), LightBlue)
End Sub

Sub Game.UpdateDraw()
    While (Not WindowShouldClose())
        Dim As Single Df = IIf(GetFrameTime() > 1/60, 1/60, GetFrameTime())
        If (IsKeyPressed(KEY_P) And Not This.Player.GameOver) Then
            This.Paused = Not This.Paused
        End If

        If (IsKeyPressed(KEY_R) And This.Player.GameOver Or This.Boss.Health <= 0) Then
            This.Reset()
            Continue While
        End If

        '' Update
        If (Not This.Paused) Then
            This.CheckMusicIcon()
            This.Player.Update(Df)
            This.Player.UpdateBullet(Df, This.Boss.Body, This.Boss.Health)
            This.Boss.PlayerPosition = This.Player.Center
            This.Boss.Update(Df, This.Player.Body, This.Player.Health, This.Player.GotHit)
            This.Boss.LookAt(This.Player.Center)
        End If

        '' Draw
        BeginDrawing()
        ClearBackground(WHITE)
        This.DrawBackground()
        This.Boss.Draw()
        This.Player.Draw()
        This.Boss.DrawHealth()
        Dim As Rectangle IconRectSource = Rectangle(0, 0, This.MusicIcon.width_\2, This.MusicIcon.height_)
        IconRectSource.x = IIf(MusicVolume > 0, 0, This.MusicIcon.width_\2)
        Dim As Rectangle IconRectDest = Rectangle( _
            GetScreenWidth()-(This.MusicIcon.width_\2)-10, 0, _
            This.MusicIcon.width_\2, This.MusicIcon.height_ _
        )

        '' UI
        DrawTexturePro(_
            This.MusicIcon, IconRectSource, IconRectDest, _
            Vector2(0, 0), 0.0, WHITE _
        )
        If (This.Player.GameOver) Then
            This.Boss.LeftEye.TrackPlayer = False
            This.Boss.RightEye.TrackPlayer = False
            DrawText("GAME OVER", GetScreenWidth()\2-200, GetScreenHeight()\2-200, 80, BLACK)
            DrawText("Press R to restart", 10, GetScreenHeight()-50, 40, BLACK)
        End If

        If (This.Boss.Health <= 0) Then
            DrawText("YOU WON!", GetScreenWidth()\2-200, GetScreenHeight()\2-200, 80, BLACK)
            DrawText("Press R to restart", 10, GetScreenHeight()-50, 40, BLACK)
        End If

        If (This.Paused) Then
            DrawText("PAUSE", GetScreenWidth()\2-150, GetScreenHeight()\2-200, 80, BLACK)
            DrawText("Music by Raphaël Marcon - http://raphytator.itch.io", 10, GetScreenHeight()-50, 40, BLACK)
        End If
        #ifdef DEBUG
        DrawFPS(10, 10)
        #endif
        EndDrawing()
    #ifdef PLATFORM_DESKTOP
    Wend
    #endif
End Sub

Sub Game.Reset()
    This.Boss.Reset()
    This.Player.Reset()
End Sub