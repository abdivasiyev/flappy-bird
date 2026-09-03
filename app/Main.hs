module Main (main) where

import Control.Exception (bracket)
import Control.Monad (unless)
import Data.Kind (Type)
import Data.Text (Text)
import Foreign.C.Types (CInt)
import SDL (RendererConfig (rendererType))
import SDL.Vect

import SDL qualified
import SDL.Image qualified

type Settings :: Type
data Settings = Settings
    { screenWidth :: CInt
    , screenHeight :: CInt
    , windowTitle :: Text
    , backgroundImagePath :: FilePath
    , flappyBirdImagePath :: FilePath
    }

type GameTexture :: Type
data GameTexture = GameTexture
    { backgroundImageTexture :: SDL.Texture
    , flappyBirdTexture :: SDL.Texture
    }

mkGameTexture :: SDL.Renderer -> IO GameTexture
mkGameTexture r = do
    bgImage <- SDL.Image.loadTexture r defaultSettings.backgroundImagePath
    flappyBird <- SDL.Image.loadTexture r defaultSettings.flappyBirdImagePath

    return
        $ GameTexture
            { backgroundImageTexture = bgImage
            , flappyBirdTexture = flappyBird
            }

destroyGameTexture :: GameTexture -> IO ()
destroyGameTexture gs = do
    SDL.destroyTexture gs.backgroundImageTexture

withGameTexture :: SDL.Renderer -> (GameTexture -> IO ()) -> IO ()
withGameTexture r = bracket (mkGameTexture r) destroyGameTexture

defaultSettings :: Settings
defaultSettings =
    Settings
        { screenWidth = 360
        , screenHeight = 640
        , windowTitle = "Flappy Bird"
        , backgroundImagePath = "./assets/flappybirdbg.png"
        , flappyBirdImagePath = "./assets/flappybird.png"
        }

defaultWindowConfig :: SDL.WindowConfig
defaultWindowConfig =
    SDL.defaultWindow
        { SDL.windowInitialSize = V2 defaultSettings.screenWidth defaultSettings.screenHeight
        }

withWindow :: (SDL.Window -> IO ()) -> IO ()
withWindow = bracket (SDL.createWindow defaultSettings.windowTitle defaultWindowConfig) SDL.destroyWindow

defaultRendererConfig :: SDL.RendererConfig
defaultRendererConfig =
    SDL.defaultRenderer
        { SDL.rendererType = SDL.AcceleratedVSyncRenderer
        , SDL.rendererTargetTexture = False
        }

withRenderer :: SDL.Window -> (SDL.Renderer -> IO ()) -> IO ()
withRenderer w = bracket (SDL.createRenderer w (-1) defaultRendererConfig) SDL.destroyRenderer

gameLoop :: SDL.Window -> SDL.Renderer -> GameTexture -> IO ()
gameLoop w r gs = do
    SDL.showWindow w
    loop
    where
        loop = do
            events <- SDL.pollEvents

            let
                quit = any isQuitEvent events
                birdRect = SDL.Rectangle (P $ V2 0 320) (V2 34 24)

            SDL.clear r

            SDL.copy r gs.backgroundImageTexture Nothing Nothing
            SDL.copy r gs.flappyBirdTexture Nothing (Just birdRect)

            -- SDL.fillRect r $ Just birdRect

            SDL.present r

            unless quit loop

main :: IO ()
main = do
    SDL.initializeAll

    withWindow $ \w -> do
        withRenderer w $ \r -> do
            withGameTexture r $ \gs -> do
                gameLoop w r gs

    SDL.quit

isQuitEvent :: SDL.Event -> Bool
isQuitEvent e = case SDL.eventPayload e of
    SDL.QuitEvent -> True
    SDL.KeyboardEvent ke -> SDL.keyboardEventKeyMotion ke == SDL.Pressed && SDL.keysymKeycode (SDL.keyboardEventKeysym ke) == SDL.KeycodeEscape
    _ -> False
