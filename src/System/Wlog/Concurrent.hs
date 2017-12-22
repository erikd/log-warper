{-# LANGUAGE ConstraintKinds     #-}
{-# LANGUAGE ExplicitForAll      #-}
{-# LANGUAGE FlexibleContexts    #-}
{-# LANGUAGE ScopedTypeVariables #-}

module System.Wlog.Concurrent
       ( WaitingDelta (..)
       , CanLogInParallel
       , logWarningLongAction
       , logWarningWaitOnce
       , logWarningWaitLinear
       , logWarningWaitInf
       ) where

import Universum

import Control.Concurrent (threadDelay)
import Control.Concurrent.Async.Lifted (withAsyncWithUnmask)
import Control.Monad.Trans.Control (MonadBaseControl)
import Data.Time.Units (Microsecond, Second, convertUnit, toMicroseconds)
import Fmt

import System.Wlog.CanLog (WithLoggerIO, logWarning)

-- | Data type to represent waiting strategy for printing warnings
-- if action take too much time.
data WaitingDelta
    = WaitOnce      Second              -- ^ wait s seconds and stop execution
    | WaitLinear    Second              -- ^ wait s, s * 2, s * 3  , s * 4  , ...      seconds
    | WaitGeometric Microsecond Double  -- ^ wait m, m * q, m * q^2, m * q^3, ... microseconds
    deriving (Show)


-- | Constraint for something that can be logged in parallel with other action.
type CanLogInParallel m = (MonadBaseControl IO m, WithLoggerIO m)

-- | Run action and print warning if it takes more time than expected.
logWarningLongAction
    :: forall m a .
       CanLogInParallel m
    => (Text -> m ()) -> WaitingDelta -> Text -> m a -> m a
logWarningLongAction logFunc delta actionTag action =
    -- Previous implementation was
    --
    --   bracket (fork $ waitAndWarn delta) killThread (const action)
    --
    -- but this has a subtle problem: 'killThread' can be interrupted even
    -- when exceptions are masked, so it's possible that the forked thread is
    -- left running, polluting the logs with misinformation.
    --
    -- 'withAsync' is assumed to take care of this, and indeed it does for
    -- 'Production's implementation, which uses the definition from the async
    -- package: 'uninterruptibleCancel' is used to kill the thread.
    --
    -- thinking even more about it, unmasking auxilary thread is crucial if
    -- this function is going to be called under 'mask'.
    withAsyncWithUnmask (\unmask -> unmask $ waitAndWarn delta) (const action)
  where
    printWarning :: Second -> m ()
    printWarning t = logFunc $ "Action `"+|actionTag|+"` took more than "+||t||+""

    waitAndWarn :: WaitingDelta -> m ()
    waitAndWarn (WaitOnce      s  ) = delayAndPrint s s
    waitAndWarn (WaitLinear    s  ) =
        let waitLoop acc = do
                delayAndPrint s acc
                waitLoop (acc + s)
        in waitLoop s
    waitAndWarn (WaitGeometric s q) =
        let waitLoop acc t = do
                let newAcc = acc + t
                let newT   = round $ fromIntegral t * q
                delayAndPrint t (convertUnit newAcc :: Second)
                waitLoop newAcc newT
        in waitLoop 0 s

    delayAndPrint s t = do
        liftIO $ threadDelay $ fromInteger $ toMicroseconds s
        printWarning t

{- Helper functions to avoid dealing with data type -}

-- | Specialization of 'logWarningLongAction' with 'WaitOnce'.
logWarningWaitOnce :: CanLogInParallel m => Second -> Text -> m a -> m a
logWarningWaitOnce = logWarningLongAction logWarning . WaitOnce

-- | Specialization of 'logWarningLongAction' with 'WaiLinear'.
logWarningWaitLinear :: CanLogInParallel m => Second -> Text -> m a -> m a
logWarningWaitLinear = logWarningLongAction logWarning . WaitLinear

-- | Specialization of 'logWarningLongAction' with 'WaitGeometric'
-- with parameter @1.3@. Accepts 'Second'.
logWarningWaitInf :: CanLogInParallel m => Second -> Text -> m a -> m a
logWarningWaitInf = logWarningLongAction logWarning . (`WaitGeometric` 1.3) . convertUnit
