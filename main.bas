#define PLATFORM_DESKTOP
#undef DEBUG
#include "game.bas"
Dim As Game CurrentGame = Game(1240, 720, "Flag wars")
CurrentGame.InitBoss( _
    "assets/graphics/sun1.png", "assets/graphics/rays.png", "assets/graphics/eyeball.png", _
    Vector2(555, 310) _
)
CurrentGame.InitPlayer("assets/graphics/uy_sun.png", "assets/graphics/uy_ray.png", Vector2(230, 400), 300)
CurrentGame.UpdateDraw()
