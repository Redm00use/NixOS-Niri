{
  config,
  ...
}:
{
  programs.noctalia-shell =
    with config.lib.stylix.colors;
    let
      homeDir = config.home.homeDirectory;
      font = config.stylix.fonts.monospace;
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
          "viewMode" = "grid";
        };
        "audio" = {
          "cavaFrameRate" = 30;
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
          "floating" = false;
          "marginHorizontal" = 0.25;
          "marginVertical" = 0.5;
          "monitors" = [ ];
          "outerCorners" = true;
          "position" = "right";
          "showCapsule" = true;
          "widgets" = {
            "center" = [
              {
                "characterCount" = 2;
                "followFocusedScreen" = true;
                "hideUnoccupied" = true;
                "id" = "Workspace";
                "labelMode" = "none";
              }
            ];
            "left" = [
              {
                "customFont" = "";
                "formatHorizontal" = "HH:mm ddd, MMM dd";
                "formatVertical" = "HH mm - dd MM";
                "id" = "Clock";
                "useCustomFont" = false;
                "usePrimaryColor" = true;
              }
              {
                "diskPath" = "/";
                "id" = "SystemMonitor";
                "showCpuTemp" = true;
                "showCpuUsage" = true;
                "showDiskUsage" = true;
                "showMemoryAsPercent" = true;
                "showMemoryUsage" = true;
                "showNetworkStats" = false;
                "usePrimaryColor" = true;
              }
              {
                "hideMode" = "hidden";
                "hideWhenIdle" = false;
                "id" = "MediaMini";
                "maxWidth" = 145;
                "scrollingMode" = "hover";
                "showAlbumArt" = true;
                "showArtistFirst" = true;
                "showProgressRing" = true;
                "showVisualizer" = false;
                "useFixedWidth" = false;
                "visualizerType" = "linear";
              }
            ];
            "right" = [
              {
                "blacklist" = [ ];
                "colorizeIcons" = true;
                "drawerEnabled" = true;
                "id" = "Tray";
                "pinned" = [ ];
              }
              { "id" = "ScreenRecorder"; }
              {
                "displayMode" = "onhover";
                "id" = "VPN";
              }
              {
                "hideWhenZero" = true;
                "id" = "NotificationHistory";
                "showUnreadBadge" = true;
              }
              {
                "deviceNativePath" = "";
                "displayMode" = "onhover";
                "id" = "Battery";
                "warningThreshold" = 30;
              }
              {
                "displayMode" = "onhover";
                "id" = "Volume";
              }
              {
                "displayMode" = "onhover";
                "id" = "Brightness";
              }
              {
                "colorizeDistroLogo" = false;
                "colorizeSystemIcon" = "none";
                "customIconPath" = "";
                "enableColorization" = false;
                "icon" = "cat";
                "id" = "ControlCenter";
                "useDistroLogo" = true;
              }
            ];
          };
        };
        "brightness" = {
          "brightnessStep" = 5;
          "enableDdcSupport" = false;
          "enforceMinimum" = true;
        };
        "calendar" = {
          "cards" = [
            {
              "enabled" = true;
              "id" = "calendar-header-card";
            }
            {
              "enabled" = true;
              "id" = "calendar-month-card";
            }
            {
              "enabled" = true;
              "id" = "timer-card";
            }
            {
              "enabled" = false;
              "id" = "weather-card";
            }
          ];
        };
        "changelog" = {
          "lastSeenVersion" = "";
        };
        "colorSchemes" = {
          "darkMode" = true;
          "generateTemplatesForPredefined" = true;
          "manualSunrise" = "06:30";
          "manualSunset" = "18:30";
          "matugenSchemeType" = "scheme-fruit-salad";
          "predefinedScheme" = "Noctalia (default)";
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
          "displayMode" = "auto_hide";
          "enabled" = false;
          "floatingRatio" = 1;
          "monitors" = [ ];
          "onlySameOutput" = true;
          "pinnedApps" = [ ];
          "size" = 1;
        };
        "general" = {
          "allowPanelsOnScreenWithoutBar" = true;
          "animationDisabled" = false;
          "animationSpeed" = 1;
          "avatarImage" = "${homeDir}/.face";
          "boxRadiusRatio" = 1;
          "compactLockScreen" = false;
          "dimmerOpacity" = 0.5;
          "enableShadows" = true;
          "forceBlackScreenCorners" = false;
          "iRadiusRatio" = 1;
          "language" = "";
          "lockOnSuspend" = true;
          "radiusRatio" = 1;
          "scaleRatio" = 0.9;
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
          "wallpaperChange" = "";
        };
        "location" = {
          "analogClockInCalendar" = false;
          "firstDayOfWeek" = -1;
          "name" = "Goiânia";
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
          "enabledTypes" = [
            0
            1
            2
          ];
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
        "settingsVersion" = 26;
        "systemMonitor" = {
          "cpuCriticalThreshold" = 90;
          "cpuPollingInterval" = 3000;
          "cpuWarningThreshold" = 80;
          "criticalColor" = "";
          "diskCriticalThreshold" = 90;
          "diskPollingInterval" = 3000;
          "diskWarningThreshold" = 80;
          "memCriticalThreshold" = 90;
          "memPollingInterval" = 3000;
          "memWarningThreshold" = 80;
          "networkPollingInterval" = 3000;
          "tempCriticalThreshold" = 90;
          "tempPollingInterval" = 3000;
          "tempWarningThreshold" = 80;
          "useCustomColors" = false;
          "warningColor" = "";
        };
        "templates" = {
          "alacritty" = false;
          "cava" = false;
          "code" = false;
          "discord" = false;
          "emacs" = false;
          "enableUserTemplates" = false;
          "foot" = false;
          "fuzzel" = false;
          "ghostty" = false;
          "gtk" = false;
          "kcolorscheme" = false;
          "kitty" = false;
          "niri" = false;
          "pywalfox" = false;
          "qt" = false;
          "spicetify" = false;
          "telegram" = false;
          "vicinae" = false;
          "walker" = false;
          "wezterm" = false;
        };
        "ui" = {
          "fontDefault" = "${font.name}";
          "fontDefaultScale" = 1;
          "fontFixed" = "${font.name}";
          "fontFixedScale" = 1;
          "panelBackgroundOpacity" = 1;
          "panelsAttachedToBar" = true;
          "settingsPanelAttachToBar" = true;
          "tooltipsEnabled" = true;
        };
        "wallpaper" = {
          "directory" = "${homeDir}/nixdots/assets/wallpapers";
          "enableMultiMonitorDirectories" = false;
          "enabled" = true;
          "fillColor" = "#000000";
          "fillMode" = "crop";
          "hideWallpaperFilenames" = true;
          "monitorDirectories" = [ ];
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
