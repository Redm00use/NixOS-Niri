{
  config,
  pkgs,
  unstable,
  ...
}:
{
  programs.noctalia-shell =
    with config.lib.stylix.colors;
    let
      homeDir = config.home.homeDirectory;
    in
    {
      enable = true;

      colors = {
        mError = "#${base08}";
        mHover = "#${base0D}";
        mOnError = "#${base00}";
        mOnPrimary = "#${base00}";
        mOnSecondary = "#${base00}";
        mOnSurface = "#${base04}";
        mOnSurfaceVariant = "#${base04}";
        mOnTertiary = "#${base00}";
        mOutline = "#${base02}";
        mPrimary = "#${base0B}";
        mSecondary = "#${base0A}";
        mShadow = "#${base00}";
        mSurface = "#${base00}";
        mSurfaceVariant = "#${base01}";
        mTertiary = "#${base0D}";
      };
      settings = {
        "appLauncher" = {
          "customLaunchPrefix" = "";
          "customLaunchPrefixEnabled" = false;
          "enableClipPreview" = true;
          "enableClipboardHistory" = true;
          "pinnedExecs" = [ ];
          "position" = "follow_bar";
          "sortByMostUsed" = true;
          "terminalCommand" = "wezterm start --";
          "useApp2Unit" = false;
          "viewMode" = "list";
        };
        "audio" = {
          "cavaFrameRate" = 60;
          "externalMixer" = "pwvucontrol || pavucontrol";
          "mprisBlacklist" = [ ];
          "preferredPlayer" = "";
          "visualizerQuality" = "high";
          "visualizerType" = "wave";
          "volumeOverdrive" = false;
          "volumeStep" = 5;
        };
        "bar" = {
          "backgroundOpacity" = 1;
          "capsuleOpacity" = 1;
          "density" = "comfortable";
          "exclusive" = true;
          "floating" = true;
          "marginHorizontal" = 0.25;
          "marginVertical" = 0.55;
          "monitors" = [ ];
          "outerCorners" = false;
          "position" = "right";
          "showCapsule" = true;
          "widgets" = {
            "center" = [
              {
                "id" = "Spacer";
                "width" = 20;
              }
              {
                "characterCount" = 2;
                "followFocusedScreen" = false;
                "hideUnoccupied" = true;
                "id" = "Workspace";
                "labelMode" = "none";
              }
            ];
            "left" = [
              {
                "colorizeDistroLogo" = false;
                "customIconPath" = "";
                "icon" = "";
                "id" = "ControlCenter";
                "useDistroLogo" = true;
              }
              {
                "customFont" = "";
                "formatHorizontal" = "HH:mm ddd, MMM dd";
                "formatVertical" = "HH mm - dd MM";
                "id" = "Clock";
                "useCustomFont" = false;
                "usePrimaryColor" = true;
              }
              {
                "displayMode" = "onhover";
                "id" = "Brightness";
              }
              {
                "displayMode" = "onhover";
                "id" = "Volume";
              }
              {
                "hideWhenZero" = true;
                "id" = "NotificationHistory";
                "showUnreadBadge" = true;
              }
              { "id" = "ScreenRecorder"; }
              {
                "blacklist" = [ ];
                "colorizeIcons" = false;
                "drawerEnabled" = true;
                "id" = "Tray";
                "pinned" = [ ];
              }
            ];
            "right" = [
              {
                "hideMode" = "hidden";
                "hideWhenIdle" = false;
                "id" = "MediaMini";
                "maxWidth" = 145;
                "scrollingMode" = "never";
                "showAlbumArt" = true;
                "showArtistFirst" = true;
                "showProgressRing" = true;
                "showVisualizer" = true;
                "useFixedWidth" = true;
                "visualizerType" = "wave";
              }
              {
                "displayMode" = "alwaysShow";
                "id" = "VPN";
              }
              {
                "diskPath" = "/";
                "id" = "SystemMonitor";
                "showCpuTemp" = true;
                "showCpuUsage" = true;
                "showDiskUsage" = false;
                "showMemoryAsPercent" = true;
                "showMemoryUsage" = true;
                "showNetworkStats" = false;
                "usePrimaryColor" = true;
              }
            ];
          };
        };
        "brightness" = {
          "brightnessStep" = 5;
          "enableDdcSupport" = false;
          "enforceMinimum" = true;
        };
        "changelog" = {
          "lastSeenVersion" = "";
        };
        "colorSchemes" = {
          "darkMode" = true;
          "generateTemplatesForPredefined" = false;
          "manualSunrise" = "06:30";
          "manualSunset" = "18:30";
          "matugenSchemeType" = "scheme-fruit-salad";
          "predefinedScheme" = "Gruvbox";
          "schedulingMode" = "off";
          "useWallpaperColors" = false;
        };
        "controlCenter" = {
          "cards" = [
            {
              "enabled" = true;
              "id" = "profile-card";
            }
            {
              "enabled" = true;
              "id" = "shortcuts-card";
            }
            {
              "enabled" = false;
              "id" = "audio-card";
            }
            {
              "enabled" = true;
              "id" = "weather-card";
            }
            {
              "enabled" = true;
              "id" = "media-sysmon-card";
            }
          ];
          "position" = "close_to_bar_button";
          "shortcuts" = {
            "left" = [
              { "id" = "WiFi"; }
              { "id" = "Bluetooth"; }
              { "id" = "ScreenRecorder"; }
              { "id" = "WallpaperSelector"; }
            ];
            "right" = [
              { "id" = "Notifications"; }
              { "id" = "PowerProfile"; }
              { "id" = "KeepAwake"; }
              { "id" = "NightLight"; }
            ];
          };
        };
        "dock" = {
          "backgroundOpacity" = 1;
          "colorizeIcons" = false;
          "displayMode" = "always_visible";
          "enabled" = false;
          "floatingRatio" = 1;
          "monitors" = [ ];
          "onlySameOutput" = true;
          "pinnedApps" = [ ];
          "radiusRatio" = 0.6;
          "size" = 1;
        };
        "general" = {
          "allowPanelsOnScreenWithoutBar" = true;
          "animationDisabled" = false;
          "animationSpeed" = 1;
          "avatarImage" = "${homeDir}/.face";
          "compactLockScreen" = false;
          "dimmerOpacity" = 0.4;
          "enableShadows" = true;
          "forceBlackScreenCorners" = false;
          "language" = "";
          "lockOnSuspend" = true;
          "radiusRatio" = 1;
          "scaleRatio" = 0.9500000000000001;
          "screenRadiusRatio" = 1;
          "shadowDirection" = "bottom_right";
          "shadowOffsetX" = 2;
          "shadowOffsetY" = 3;
          "showHibernateOnLockScreen" = false;
          "showScreenCorners" = true;
        };
        "hooks" = {
          "darkModeChange" = "";
          "enabled" = false;
          "wallpaperChange" = "cp $1 ~/.wallpaper || rm -rf ~/.wallpaper && cp $1 ~/.wallpaper";
        };
        "location" = {
          "analogClockInCalendar" = false;
          "firstDayOfWeek" = -1;
          "name" = "Goiânia, Go";
          "showCalendarEvents" = true;
          "showCalendarWeather" = true;
          "showWeekNumberInCalendar" = false;
          "use12hourFormat" = false;
          "useFahrenheit" = false;
          "weatherEnabled" = true;
          "weatherShowEffects" = true;
        };
        "network" = {
          "wifiEnabled" = true;
        };
        "nightLight" = {
          "autoSchedule" = true;
          "dayTemp" = "6500";
          "enabled" = false;
          "forced" = false;
          "manualSunrise" = "06:30";
          "manualSunset" = "18:30";
          "nightTemp" = "4000";
        };
        "notifications" = {
          "backgroundOpacity" = 1;
          "criticalUrgencyDuration" = 15;
          "enableKeyboardLayoutToast" = true;
          "enabled" = true;
          "location" = "top_right";
          "lowUrgencyDuration" = 3;
          "monitors" = [ ];
          "normalUrgencyDuration" = 8;
          "overlayLayer" = true;
          "respectExpireTimeout" = false;
        };
        "osd" = {
          "autoHideMs" = 2000;
          "backgroundOpacity" = 1;
          "enabled" = true;
          "location" = "top_right";
          "monitors" = [ ];
          "overlayLayer" = true;
        };
        "screenRecorder" = {
          "audioCodec" = "opus";
          "audioSource" = "default_output";
          "colorRange" = "limited";
          "directory" = "${homeDir}/Videos";
          "frameRate" = 60;
          "quality" = "very_high";
          "showCursor" = true;
          "videoCodec" = "h264";
          "videoSource" = "portal";
        };
        "sessionMenu" = {
          "countdownDuration" = 10000;
          "enableCountdown" = true;
          "position" = "center";
          "powerOptions" = [
            {
              "action" = "lock";
              "countdownEnabled" = true;
              "enabled" = true;
            }
            {
              "action" = "suspend";
              "countdownEnabled" = true;
              "enabled" = true;
            }
            {
              "action" = "hibernate";
              "countdownEnabled" = true;
              "enabled" = true;
            }
            {
              "action" = "reboot";
              "countdownEnabled" = true;
              "enabled" = true;
            }
            {
              "action" = "logout";
              "countdownEnabled" = true;
              "enabled" = true;
            }
            {
              "action" = "shutdown";
              "countdownEnabled" = true;
              "enabled" = true;
            }
          ];
          "showHeader" = true;
        };
        "settingsVersion" = 23;
        "setupCompleted" = true;
        "systemMonitor" = {
          "cpuCriticalThreshold" = 90;
          "cpuWarningThreshold" = 80;
          "criticalColor" = "#d43847";
          "diskCriticalThreshold" = 90;
          "diskWarningThreshold" = 80;
          "memCriticalThreshold" = 90;
          "memWarningThreshold" = 80;
          "tempCriticalThreshold" = 90;
          "tempWarningThreshold" = 80;
          "useCustomColors" = false;
          "warningColor" = "#9f2231";
        };
        "templates" = {
          "alacritty" = false;
          "cava" = false;
          "code" = false;
          "discord" = false;
          "enableUserTemplates" = false;
          "foot" = false;
          "fuzzel" = false;
          "ghostty" = false;
          "gtk" = false;
          "kcolorscheme" = false;
          "kitty" = false;
          "pywalfox" = false;
          "qt" = false;
          "spicetify" = false;
          "telegram" = false;
          "vicinae" = false;
          "walker" = false;
          "wezterm" = false;
        };
        "ui" = {
          "fontDefault" = "MonaspiceRn NF";
          "fontDefaultScale" = 1;
          "fontFixed" = "MonaspiceRn Nerd Font Mono";
          "fontFixedScale" = 1.1;
          "panelBackgroundOpacity" = 1;
          "panelsAttachedToBar" = true;
          "settingsPanelAttachToBar" = false;
          "tooltipsEnabled" = true;
        };
        "wallpaper" = {
          "defaultWallpaper" = "${../../../../assets/wallpapers/wallhaven_6qojow.jpg}";
          "directory" = "${homeDir}/nixdots/assets/wallpapers";
          "enableMultiMonitorDirectories" = false;
          "enabled" = true;
          "fillColor" = "#000000";
          "fillMode" = "crop";
          "hideWallpaperFilenames" = true;
          "monitors" = [ ];
          "overviewEnabled" = true;
          "panelPosition" = "follow_bar";
          "randomEnabled" = false;
          "randomIntervalSec" = 300;
          "recursiveSearch" = false;
          "setWallpaperOnAllMonitors" = true;
          "transitionDuration" = 1500;
          "transitionEdgeSmoothness" = 0.05;
          "transitionType" = "random";
          "useWallhaven" = false;
          "wallhavenCategories" = "111";
          "wallhavenOrder" = "desc";
          "wallhavenPurity" = "100";
          "wallhavenQuery" = "";
          "wallhavenResolutionHeight" = "";
          "wallhavenResolutionMode" = "atleast";
          "wallhavenResolutionWidth" = "";
          "wallhavenSorting" = "relevance";
        };
      };
    };
}
