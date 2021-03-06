module Play where
import Graphics.Gloss
import Graphics.Gloss.Interface.Pure.Game
import DataType
import Graphics.Gloss.Data.ViewPort
import Data.Char
import Data.List

type WordNum = String


-- Update the game by moving the ball and bouncing off walls. (function composition)
updatePlay ::  Float -> PongGame -> PongGame
updatePlay  seconds = wallBounce . moveBall seconds . paddleBounce . checkWinner . score 

-- check if there is a winner
checkWinner:: PongGame -> PongGame
checkWinner game 
                | (score1 game) > 21 = game {gamemode = Endgame}
                | (score2 game) > 21 = game {gamemode = Endgame}
                | otherwise = game 


-- | handle the playmode keys.
handlePlayKeys::Event->PongGame->PongGame
-- press 'r' to reset the game(scores/players pos/ball pos).
handlePlayKeys (EventKey (Char 'r') Down _ _) game = resetGame game
-- press 'q' to go back to the menu
handlePlayKeys (EventKey (Char 'q') Down _ _) game  = game {gamemode = Menu}
-- press 'p' to pause the game
handlePlayKeys (EventKey (Char 'p') Down _ _) game = game {gamemode = Pause}
-- press the up key to move player1 to the up
handlePlayKeys (EventKey (SpecialKey KeyUp) Down _ _) game = game { player1 = (movePaddleUp (player1 game)) }
-- press the down key to move player1 to the down
handlePlayKeys (EventKey (SpecialKey KeyDown) Down _ _) game = game { player1 = (movePaddleDown (player1 game)) }
-- press the up'w' key to move player2 to the up
handlePlayKeys (EventKey (Char 'w') Down _ _) game = game { player2 = (movePaddleUp (player2 game)) }
-- press the 's' key to move player2 to the down
handlePlayKeys (EventKey (Char 's') Down _ _) game = game { player2 = (movePaddleDown (player2 game)) }
-- otherwise->do not change
handlePlayKeys evnent game = game

ones ::  Float -> String
ones 0 = "0"
ones 1 = "1"
ones 2 = "2"
ones 3 = "3"
ones 4 = "4"
ones 5 = "5"
ones 6 = "6"
ones 7 = "7"
ones 8 = "8"
ones 9 = "9"
ones 10 = "10"
ones 11 = "1 up"
ones 12 = "2 up"
ones 13 = "3 up"
ones 14 = "4 up"
ones 15 = "5 up"
ones 16 = "6 up"
ones 17 = "7 up"
ones 18 = "8 up"
ones 19 = "9 up"
ones 20 = "Last"
ones 21 = "Game"
ones _  = "End"


-- | Convert a game state into a picture.
renderPlay :: PongGame  -- ^ The game state to render.
       -> Picture   -- ^ A picture of this game state.
renderPlay game =
  pictures [ball, walls,
            mkPaddle rose (fromIntegral width / 2 - 15) $ player1 game,
            mkPaddle orange (fromIntegral (-width) / 2 + 15) $ player2 game,
            translate 0 0 $ color ballColor $ circle 15,
            translate 0 0 $ color ballColor $ rectangleSolid 1 (fromIntegral height),
            scale (0.3) (0.3) (translate (600) (1000) $ color rose (text  num1)),
            scale (0.3) (0.3) (translate (-1300) (1000) $ color orange (text  num2))

            ]
  where
    --  The pong ball.
    ball = uncurry translate (ballLoc game) $ color ballColor $ circleSolid 15
    ballColor = dark red
    -- 
    num1 = "Player1: " ++ ones (score1 game)
    num2 = "Player2: " ++ ones (score2 game)

    --  The bottom and top walls.
    wall :: Float -> Picture
    wall offset =
      translate 0 offset $
        color wallColor $
          rectangleSolid (fromIntegral width) 10

    wallColor = greyN 0.5
    walls = pictures [wall (fromIntegral height/2 - 5), wall (fromIntegral (-height) / 2 + 5)]

    --  Make a paddle of a given border and vertical offset.
    mkPaddle :: Color -> Float -> Float -> Picture
    mkPaddle col x y = pictures
      [ translate x y $ color col $ rectangleSolid 26 86
      , translate x y $ color paddleColor $ rectangleSolid 20 80
      ]

    paddleColor = light (light blue)

-- | Update the ball position using its current velocity.
moveBall :: Float    -- ^ The number of seconds since last update
         -> PongGame -- ^ The initial game state
         -> PongGame -- ^ A new game state with an updated ball position
moveBall seconds game = game { ballLoc = (x', y') }
  where
    -- Old locations and velocities.
    (x, y) = ballLoc game
    (vx, vy) = ballVel game

    -- New locations.
    x' = x + vx * seconds * 100
    y' = y + vy * seconds * 100



type Radius = Float 
type BallVelocity = (Float, Float)

-- move paddle
movePaddleUp :: Float -> Float
movePaddleUp pos | wallCollisionPaddleTop pos 52 = pos
                  | otherwise = (pos + 40)

movePaddleDown :: Float -> Float
movePaddleDown pos | wallCollisionPaddleBottom pos 52 = pos
                  | otherwise = (pos - 40)

-- | Given height of the paddle, return whether a collision between paddle and wall occurred.
wallCollisionPaddleTop :: Float -> Float -> Bool 
wallCollisionPaddleTop y paddleHeight = bottomCollision
  where
    bottomCollision = y + paddleHeight >=  fromIntegral height / 2

wallCollisionPaddleBottom :: Float -> Float -> Bool 
wallCollisionPaddleBottom y paddleHeight = topCollision
  where 
    topCollision    = y - paddleHeight <= -fromIntegral height / 2

-- | Given position and radius of the ball, return whether a collision occurred.
wallCollision :: BallVelocity -> Radius -> Bool 
wallCollision (_, y) radius = topCollision || bottomCollision
  where
    topCollision    = y - radius <= -fromIntegral height / 2 +12
    bottomCollision = y + radius >=  fromIntegral height / 2 -12

score :: PongGame -> PongGame
score game = game { ballLoc = (x', y'), score2=s2', score1=s1'}
  where
    s1 = score1 game
    s2 = score2 game
    (x, y) = ballLoc  game
    s2' = if (x >= 600)
          then
             s2+1
           else
            s2
    s1' = if (x <= -600)
          then
             s1+1
           else
            s1

    x' = if (x >= 600 || x<= -600)
          then
             0
           else
            x
    y' = if (x >= 600 || x<= -600)
          then
             0
           else
            y
 
  
            
wallBounce :: PongGame -> PongGame
wallBounce game = game { ballVel = (vx, vy') }
  where
    radius = 10

    -- The old velocities.
    (vx, vy) = ballVel game

    vy' = if wallCollision (ballLoc game) radius
          then
             -- Update the velocity.
             -vy
           else
            -- Do nothing. Return the old velocity.
            vy



paddleCollision :: BallVelocity -> Float -> Float -> Radius -> Bool 
paddleCollision (x, y) p1 p2 radius = leftCollision || rightCollision
  where
    leftCollision  = (x - radius <= -fromIntegral (width-80) / 2) && (y >= (p2 - 50)  && y <= (p2 + 50))
    rightCollision = (x + radius >= fromIntegral (width-80) / 2) && (y >= (p1 - 50)  && y <= (p1 + 50))


paddleBounce :: PongGame -> PongGame
paddleBounce game = game { ballVel = (vx', vy) }
  where
    -- Radius. Use the same thing as in `render`.
    radius = 10

    -- The old velocities.
    (vx, vy) = ballVel game

    vx' = if paddleCollision (ballLoc game) (player1 game) (player2 game) radius
          then
             -- Update the velocity.
             -vx
           else
            -- Do nothing. Return the old velocity.
            vx

--Reset game
resetGame :: PongGame -> PongGame
resetGame game = game{ballLoc = (0, 0), score1  = 0, score2  = 0, player1 = 100, player2 = -100}
