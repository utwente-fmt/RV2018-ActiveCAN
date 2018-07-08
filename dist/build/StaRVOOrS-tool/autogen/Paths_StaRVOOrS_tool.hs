{-# LANGUAGE CPP #-}
{-# OPTIONS_GHC -fno-warn-missing-import-lists #-}
{-# OPTIONS_GHC -fno-warn-implicit-prelude #-}
module Paths_StaRVOOrS_tool (
    version,
    getBinDir, getLibDir, getDynLibDir, getDataDir, getLibexecDir,
    getDataFileName, getSysconfDir
  ) where

import qualified Control.Exception as Exception
import Data.Version (Version(..))
import System.Environment (getEnv)
import Prelude

#if defined(VERSION_base)

#if MIN_VERSION_base(4,0,0)
catchIO :: IO a -> (Exception.IOException -> IO a) -> IO a
#else
catchIO :: IO a -> (Exception.Exception -> IO a) -> IO a
#endif

#else
catchIO :: IO a -> (Exception.IOException -> IO a) -> IO a
#endif
catchIO = Exception.catch

version :: Version
version = Version [1,6,1,3] []
bindir, libdir, dynlibdir, datadir, libexecdir, sysconfdir :: FilePath

bindir     = "/Users/wytseoortwijn/.cabal/bin"
libdir     = "/Users/wytseoortwijn/.cabal/lib/x86_64-osx-ghc-8.2.2/StaRVOOrS-tool-1.6.1.3-3rc1HKvZcAP68GbazfG7ce-StaRVOOrS-tool"
dynlibdir  = "/Users/wytseoortwijn/.cabal/lib/x86_64-osx-ghc-8.2.2"
datadir    = "/Users/wytseoortwijn/.cabal/share/x86_64-osx-ghc-8.2.2/StaRVOOrS-tool-1.6.1.3"
libexecdir = "/Users/wytseoortwijn/.cabal/libexec/x86_64-osx-ghc-8.2.2/StaRVOOrS-tool-1.6.1.3"
sysconfdir = "/Users/wytseoortwijn/.cabal/etc"

getBinDir, getLibDir, getDynLibDir, getDataDir, getLibexecDir, getSysconfDir :: IO FilePath
getBinDir = catchIO (getEnv "StaRVOOrS_tool_bindir") (\_ -> return bindir)
getLibDir = catchIO (getEnv "StaRVOOrS_tool_libdir") (\_ -> return libdir)
getDynLibDir = catchIO (getEnv "StaRVOOrS_tool_dynlibdir") (\_ -> return dynlibdir)
getDataDir = catchIO (getEnv "StaRVOOrS_tool_datadir") (\_ -> return datadir)
getLibexecDir = catchIO (getEnv "StaRVOOrS_tool_libexecdir") (\_ -> return libexecdir)
getSysconfDir = catchIO (getEnv "StaRVOOrS_tool_sysconfdir") (\_ -> return sysconfdir)

getDataFileName :: FilePath -> IO FilePath
getDataFileName name = do
  dir <- getDataDir
  return (dir ++ "/" ++ name)
