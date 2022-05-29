#include "raylib.bi"
#define PLATFORM_DESKTOP

InitWindow(800, 600, "Test")
'' If we were compiling for the web, we don't want to set 60 FPS
#ifdef PLATFORM_DESKTOP
SetTargetFPS(60)
#endif

Sub GetX(ByRef X As Integer)
    X = GetRandomValue(0, 100)
End Sub

Dim As Integer X = 0
While (Not WindowShouldClose())
    BeginDrawing()
    ClearBackground(BLACK)
    GetX(X)
    DrawText("Hello world", X, 200, 20, WHITE)
    EndDrawing()    
Wend

CloseWindow()