module Main (main) where

import Control.Monad (unless, void)
import Foreign.C.Types (CInt)
import SDL.Vect

import SDL qualified
import SDL.Image qualified

screenWidth, screenHeight :: CInt
(screenWidth, screenHeight) = (360, 640)

main :: IO ()
main = do
    SDL.initializeAll

    w <- SDL.createWindow "Flappy Bird" SDL.defaultWindow {SDL.windowInitialSize = V2 screenWidth screenHeight}
    SDL.showWindow w

    helloWorld <- SDL.Image.load "./assets/flappybirdbg.png"

    let
        loop = do
            events <- SDL.pollEvents

            let
                quit = any isQuitEvent events

            screen <- SDL.getWindowSurface w
            void $ SDL.surfaceBlit helloWorld Nothing screen Nothing
            SDL.updateWindowSurface w
            SDL.delay 16

            unless quit loop

    loop

    SDL.freeSurface helloWorld
    SDL.destroyWindow w
    SDL.quit

isQuitEvent :: SDL.Event -> Bool
isQuitEvent e = case SDL.eventPayload e of
    SDL.QuitEvent -> True
    SDL.KeyboardEvent ke -> SDL.keyboardEventKeyMotion ke == SDL.Pressed && SDL.keysymKeycode (SDL.keyboardEventKeysym ke) == SDL.KeycodeEscape
    _ -> False
