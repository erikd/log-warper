-- | Contains @newtype@ wrapper around logger name to support hierarchy.

module System.Wlog.LoggerName
       ( LoggerName (..)
       , loggerNameF
       ) where

import           Data.Hashable       (Hashable)
import           Data.Semigroup      (Semigroup)
import qualified Data.Semigroup      as Semigroup
import           Data.String         (IsString)
import           Data.Text.Buildable (Buildable)
import qualified Data.Text.Buildable as Buildable
import           Formatting          (Format, bprint, build, string)

-- | Logger name to keep in context.

-- TODO: replace 'String' with 'Text'
-- TODO: change field name into @getLoggerName@ to follow naming convention
newtype LoggerName = LoggerName
    { loggerName :: String
    } deriving (Show, IsString, Eq, Hashable)

-- | Defined such that @n1@ is parent for @(n1 <> n2)@
-- (see <http://hackage.haskell.org/package/hslogger-1.2.10/docs/System-Log-Logger.html hslogger description>).
instance Semigroup LoggerName where
    LoggerName base <> LoggerName suffix
        | null base   = LoggerName suffix
        | null suffix = LoggerName base
        | otherwise   = LoggerName $ base ++ "." ++ suffix

instance Monoid LoggerName where
    mempty = ""
    mappend = (Semigroup.<>)

instance Buildable LoggerName where
    build = bprint string . loggerName

-- | 'LoggerName' formatter which restricts type.
loggerNameF :: Format r (LoggerName -> r)
loggerNameF = build