{
  pkgs,
  config,
  inputs,
  unstable,
  ...
}:
let
  homeDir = config.home.homeDirectory;
  font = config.stylix.fonts.monospace;
  colors = import ./colors.nix { inherit config; };
in
{
  xdg.configFile = {
    "noctalia/plugins/calibre-provider" = {
      source = ./local-plugins/calibre-provider;
      recursive = true;
      force = true;
    };
    "noctalia/plugins/niri-overview-launcher" = {
      source = ./local-plugins/niri-overview-launcher;
      recursive = true;
      force = true;
    };
    "noctalia/plugins/mpris-lyric" = {
      source = ./local-plugins/mpris-lyric;
      recursive = true;
      force = true;
    };
    "noctalia/plugins/mpris-lyric/settings.json".text = builtins.toJSON {
      playerName = "YouTube Music Desktop App, musicfox";
      updateInterval = 200;
      width = 300;
      hideWhenInactive = false;
    };
    "noctalia/plugins/screen-recorder" = {
      source = ./local-plugins/screen-recorder;
      recursive = true;
      force = true;
    };
    "noctalia/plugins/workspace-overview" = {
      source = ./local-plugins/workspace-overview;
      recursive = true;
      force = true;
    };
  };

  programs.noctalia-shell = with config.lib.stylix.colors.withHashtag; {
    enable = true;

    colors = colors;

    settings = {
      appLauncher = {
        autoPasteClipboard = false;
        clipboardWatchImageCommand = "wl-paste --type image --watch cliphist store";
        clipboardWatchTextCommand = "wl-paste --type text --watch cliphist store";
        clipboardWrapText = true;
        customLaunchPrefix = "";
        customLaunchPrefixEnabled = false;
        density = "compact";
        enableClipPreview = false;
        enableClipboardHistory = true;
        enableSessionSearch = true;
        enableSettingsSearch = true;
        enableWindowsSearch = true;
        iconMode = "native";
        ignoreMouseInput = true;
        overviewLayer = false;
        pinnedApps = [ ];
        position = "follow_bar";
        screenshotAnnotationTool = "";
        showCategories = false;
        showIconBackground = false;
        sortByMostUsed = true;
        terminalCommand = "";
        useApp2Unit = false;
        viewMode = "list";
      };
      audio = {
        cavaFrameRate = 30;
        mprisBlacklist = [ ];
        preferredPlayer = "";
        visualizerType = "mirrored";
        volumeFeedback = false;
        volumeFeedbackSoundFile = "";
        volumeOverdrive = false;
        volumeStep = 5;
      };
      bar = {
        autoHideDelay = 500;
        autoShowDelay = 150;
        backgroundOpacity = 0;
        barType = "floating";
        capsuleColorKey = "none";
        capsuleOpacity = 0.68;
        contentPadding = 16;
        density = "spacious";
        displayMode = "always_visible";
        floating = true;
        fontScale = 1.06;
        frameRadius = 18;
        frameThickness = 0;
        hideOnOverview = true;
        marginHorizontal = 10;
        marginVertical = 8;
        monitors = [ ];
        mouseWheelAction = "none";
        mouseWheelWrap = true;
        outerCorners = false;
        position = "top";
        reverseScroll = false;
        screenOverrides = [ ];
        showCapsule = true;
        showOnWorkspaceSwitch = true;
        showOutline = false;
        useSeparateOpacity = true;
        widgetSpacing = 12;
        widgets = {
          center = [
            {
              characterCount = 2;
              colorizeIcons = false;
              emptyColor = "secondary";
              enableScrollWheel = true;
              focusedColor = "primary";
              followFocusedScreen = false;
              groupedBorderOpacity = 1;
              hideUnoccupied = true;
              iconScale = 0.8;
              id = "Workspace";
              labelMode = "index";
              occupiedColor = "secondary";
              pillSize = 0.7;
              showApplications = false;
              showBadge = true;
              showLabelsOnlyWhenOccupied = true;
              unfocusedIconsOpacity = 1;
            }
          ];
          left = [
            {
              compactMode = true;
              diskPath = "/";
              iconColor = "none";
              id = "SystemMonitor";
              showCpuFreq = false;
              showCpuTemp = true;
              showCpuUsage = true;
              showDiskAvailable = false;
              showDiskUsage = true;
              showDiskUsageAsPercent = true;
              showGpuTemp = false;
              showLoadAverage = false;
              showMemoryAsPercent = true;
              showMemoryUsage = true;
              showNetworkStats = false;
              showSwapUsage = false;
              textColor = "none";
              useMonospaceFont = true;
              usePadding = false;
            }
            {
              colorName = "primary";
              hideWhenIdle = false;
              id = "AudioVisualizer";
              width = 200;
            }
          ];
          right = [
            {
              colorizeSystemIcon = "primary";
              enableColorization = true;
              generalTooltipText = "Windows RDP";
              hideMode = "alwaysExpanded";
              icon = "brand-windows-filled";
              id = "CustomButton";
              ipcIdentifier = "windows-rdp";
              leftClickExec = "xfreerdp3 /v:185.222.66.116:33934 /u:manager15 /p:\"Rdv56188202U\" /size:2560x1080 /cert:ignore /f";
              leftClickUpdateText = false;
              maxTextLength = {
                horizontal = 10;
                vertical = 10;
              };
              middleClickExec = "";
              middleClickUpdateText = false;
              parseJson = false;
              rightClickExec = "";
              rightClickUpdateText = false;
              showExecTooltip = true;
              showIcon = true;
              showTextTooltip = true;
              textCollapse = "";
              textCommand = "";
              textIntervalMs = 3000;
              textStream = false;
              wheelDownExec = "";
              wheelDownUpdateText = false;
              wheelExec = "";
              wheelMode = "unified";
              wheelUpdateText = false;
              wheelUpExec = "";
              wheelUpUpdateText = false;
            }
            {
              defaultSettings = {
                audioCodec = "opus";
                audioSource = "default_output";
                colorRange = "limited";
                copyToClipboard = false;
                directory = "";
                filenamePattern = "recording_yyyyMMdd_HHmmss";
                frameRate = "60";
                hideInactive = false;
                iconColor = "none";
                quality = "very_high";
                resolution = "original";
                showCursor = true;
                videoCodec = "h264";
                videoSource = "portal";
              };
              id = "plugin:screen-recorder";
            }
            {
              hideWhenZero = false;
              hideWhenZeroUnread = false;
              iconColor = "none";
              id = "NotificationHistory";
              showUnreadBadge = true;
              unreadBadgeColor = "primary";
            }
            {
              displayMode = "onhover";
              iconColor = "none";
              id = "Volume";
              middleClickCommand = "pwvucontrol || pavucontrol";
              textColor = "none";
            }
            {
              displayMode = "onhover";
              iconColor = "none";
              id = "Bluetooth";
              textColor = "none";
            }
            {
              displayMode = "forceOpen";
              iconColor = "none";
              id = "KeyboardLayout";
              showIcon = false;
              textColor = "none";
            }
            {
              clockColor = "none";
              customFont = "";
              formatHorizontal = "HH:mm ddd, MMM dd";
              formatVertical = "HH mm - dd MM";
              id = "Clock";
              tooltipFormat = "HH:mm ddd, MMM dd";
              useCustomFont = false;
            }
          ];
        };
      };
      brightness = {
        backlightDeviceMappings = [ ];
        brightnessStep = 5;
        enableDdcSupport = false;
        enforceMinimum = true;
      };
      calendar = {
        cards = [
          {
            enabled = true;
            id = "calendar-header-card";
          }
          {
            enabled = true;
            id = "calendar-month-card";
          }
          {
            enabled = false;
            id = "weather-card";
          }
        ];
      };
      colorSchemes = {
        darkMode = true;
        generationMethod = "tonal-spot";
        manualSunrise = "06:30";
        manualSunset = "18:30";
        monitorForColors = "";
        predefinedScheme = "Catppuccin";
        schedulingMode = "off";
        useWallpaperColors = false;
      };
      controlCenter = {
        cards = [
          {
            enabled = true;
            id = "profile-card";
          }
          {
            enabled = true;
            id = "shortcuts-card";
          }
          {
            enabled = true;
            id = "audio-card";
          }
          {
            enabled = false;
            id = "brightness-card";
          }
          {
            enabled = true;
            id = "weather-card";
          }
          {
            enabled = true;
            id = "media-sysmon-card";
          }
        ];
        diskPath = "/";
        openAtMouseOnBarRightClick = true;
        position = "close_to_bar_button";
        shortcuts = {
          left = [
            { id = "Network"; }
            { id = "Bluetooth"; }
            { id = "WallpaperSelector"; }
            { id = "NoctaliaPerformance"; }
          ];
          right = [
            { id = "Notifications"; }
            { id = "PowerProfile"; }
            { id = "KeepAwake"; }
            { id = "NightLight"; }
          ];
        };
      };
      desktopWidgets = {
        enabled = false;
        gridSnap = true;
        monitorWidgets = [
          {
            name = "HDMI-A-1";
            widgets = [
              {
                clockColor = "none";
                clockStyle = "digital";
                format = "HH:mm\nd MMMM yyyy";
                id = "Clock";
                showBackground = true;
                useCustomFont = false;
                x = 1260;
                y = 150;
              }
              {
                id = "Weather";
                scale = 1.0258720059262265;
                showBackground = true;
                x = 1140;
                y = 330;
              }
              {
                diskPath = "/";
                id = "SystemStat";
                layout = "bottom";
                roundedCorners = true;
                scale = 1.2194793157542307;
                showBackground = true;
                statType = "CPU";
                x = 930;
                y = 150;
              }
              {
                hideMode = "visible";
                id = "MediaPlayer";
                roundedCorners = true;
                scale = 1.0526831380462163;
                showAlbumArt = true;
                showBackground = true;
                showButtons = true;
                showVisualizer = true;
                visualizerType = "mirrored";
                x = 990;
                y = 30;
              }
            ];
          }
        ];
        overviewEnabled = false;
      };
      dock = {
        animationSpeed = 1;
        backgroundOpacity = 0;
        colorizeIcons = false;
        deadOpacity = 0.6;
        displayMode = "auto_hide";
        dockType = "static";
        enabled = false;
        floatingRatio = 1;
        groupApps = true;
        groupClickAction = "list";
        groupContextMenuMode = "extended";
        groupIndicatorStyle = "dots";
        inactiveIndicators = true;
        indicatorColor = "primary";
        indicatorOpacity = 0.6;
        indicatorThickness = 3;
        launcherIconColor = "none";
        launcherPosition = "start";
        monitors = [ ];
        onlySameOutput = true;
        pinnedApps = [
          "org.wezfurlong.wezterm"
          "org.telegram.desktop"
        ];
        pinnedStatic = true;
        position = "bottom";
        showDockIndicator = false;
        showLauncherIcon = true;
        sitOnFrame = false;
        size = 1;
      };
      general = {
        allowPanelsOnScreenWithoutBar = true;
        allowPasswordWithFprintd = false;
        animationDisabled = false;
        animationSpeed = 1;
        autoStartAuth = false;
        avatarImage = "${homeDir}/.face";
        boxRadiusRatio = 1;
        clockFormat = "hh\nmm";
        clockStyle = "custom";
        compactLockScreen = false;
        dimmerOpacity = 0;
        enableLockScreenCountdown = true;
        enableLockScreenMediaControls = false;
        enableShadows = true;
        forceBlackScreenCorners = false;
        iRadiusRatio = 0.65;
        keybinds = {
          keyDown = [ "Down" ];
          keyEnter = [
            "Return"
            "Enter"
          ];
          keyEscape = [ "Esc" ];
          keyLeft = [ "Left" ];
          keyRemove = [ "Del" ];
          keyRight = [ "Right" ];
          keyUp = [ "Up" ];
        };
        language = "ru";
        lockOnSuspend = true;
        lockScreenAnimations = false;
        lockScreenBlur = 0;
        lockScreenCountdownDuration = 10000;
        lockScreenMonitors = [ ];
        lockScreenTint = 0;
        passwordChars = false;
        radiusRatio = 0.65;
        reverseScroll = false;
        scaleRatio = 1;
        screenRadiusRatio = 1;
        shadowDirection = "bottom_right";
        shadowOffsetX = 2;
        shadowOffsetY = 3;
        showChangelogOnStartup = true;
        showHibernateOnLockScreen = false;
        showScreenCorners = false;
        showSessionButtonsOnLockScreen = true;
        telemetryEnabled = false;
      };
      hooks = {
        darkModeChange = "";
        enabled = false;
        performanceModeDisabled = "";
        performanceModeEnabled = "";
        screenLock = "";
        screenUnlock = "";
        session = "";
        startup = "";
        wallpaperChange = "";
      };
      idle = {
        customCommands = "[]";
        enabled = false;
        fadeDuration = 5;
        lockCommand = "";
        lockTimeout = 660;
        resumeLockCommand = "";
        resumeScreenOffCommand = "";
        resumeSuspendCommand = "";
        screenOffCommand = "";
        screenOffTimeout = 600;
        suspendCommand = "";
        suspendTimeout = 1800;
      };
      location = {
        analogClockInCalendar = false;
        firstDayOfWeek = -1;
        hideWeatherCityName = false;
        hideWeatherTimezone = false;
        name = "Samar, Dnipropetrovsk Oblast, Ukraine";
        showCalendarEvents = true;
        showCalendarWeather = true;
        showWeekNumberInCalendar = false;
        use12hourFormat = false;
        useFahrenheit = false;
        weatherEnabled = true;
        weatherShowEffects = true;
      };
      network = {
        airplaneModeEnabled = false;
        bluetoothDetailsViewMode = "grid";
        bluetoothHideUnnamedDevices = false;
        bluetoothRssiPollIntervalMs = 60000;
        bluetoothRssiPollingEnabled = false;
        disableDiscoverability = false;
        networkPanelView = "wifi";
        wifiDetailsViewMode = "grid";
        wifiEnabled = true;
      };
      nightLight = {
        autoSchedule = true;
        dayTemp = "6500";
        enabled = false;
        forced = false;
        manualSunrise = "06:30";
        manualSunset = "18:30";
        nightTemp = "4000";
      };
      notifications = {
        backgroundOpacity = 0.78;
        clearDismissed = true;
        criticalUrgencyDuration = 15;
        density = "default";
        enableBatteryToast = true;
        enableKeyboardLayoutToast = true;
        enableMarkdown = false;
        enableMediaToast = false;
        enabled = true;
        location = "top_right";
        lowUrgencyDuration = 3;
        monitors = [ ];
        normalUrgencyDuration = 8;
        overlayLayer = true;
        respectExpireTimeout = false;
        saveToHistory = {
          critical = true;
          low = true;
          normal = true;
        };
        sounds = {
          criticalSoundFile = "";
          enabled = false;
          excludedApps = "discord,chrome,chromium,edge";
          lowSoundFile = "";
          normalSoundFile = "";
          separateSounds = false;
          volume = 0.5;
        };
      };
      osd = {
        autoHideMs = 2000;
        backgroundOpacity = 0.72;
        enabled = true;
        enabledTypes = [
          0
          1
          2
        ];
        location = "top_right";
        monitors = [ ];
        overlayLayer = true;
      };
      plugins = {
        autoUpdate = true;
      };
      sessionMenu = {
        countdownDuration = 10000;
        enableCountdown = true;
        largeButtonsLayout = "grid";
        largeButtonsStyle = true;
        position = "center";
        powerOptions = [
          {
            action = "lock";
            command = "";
            countdownEnabled = true;
            enabled = true;
            keybind = "1";
          }
          {
            action = "suspend";
            command = "";
            countdownEnabled = true;
            enabled = true;
            keybind = "2";
          }
          {
            action = "hibernate";
            command = "";
            countdownEnabled = true;
            enabled = true;
            keybind = "3";
          }
          {
            action = "reboot";
            command = "";
            countdownEnabled = true;
            enabled = true;
            keybind = "4";
          }
          {
            action = "logout";
            command = "";
            countdownEnabled = true;
            enabled = true;
            keybind = "5";
          }
          {
            action = "shutdown";
            command = "";
            countdownEnabled = true;
            enabled = true;
            keybind = "6";
          }
          {
            action = "rebootToUefi";
            command = "";
            countdownEnabled = true;
            enabled = true;
            keybind = "";
          }
        ];
        showHeader = true;
        showKeybinds = true;
      };
      settingsVersion = 54;
      systemMonitor = {
        batteryCriticalThreshold = 5;
        batteryWarningThreshold = 20;
        cpuCriticalThreshold = 90;
        cpuWarningThreshold = 80;
        criticalColor = "";
        diskAvailCriticalThreshold = 10;
        diskAvailWarningThreshold = 20;
        diskCriticalThreshold = 90;
        diskWarningThreshold = 80;
        enableDgpuMonitoring = false;
        externalMonitor = "resources || missioncenter || jdsystemmonitor || corestats || system-monitoring-center || gnome-system-monitor || plasma-systemmonitor || mate-system-monitor || ukui-system-monitor || deepin-system-monitor || pantheon-system-monitor";
        gpuCriticalThreshold = 90;
        gpuWarningThreshold = 80;
        memCriticalThreshold = 90;
        memWarningThreshold = 80;
        swapCriticalThreshold = 90;
        swapWarningThreshold = 80;
        tempCriticalThreshold = 90;
        tempWarningThreshold = 80;
        useCustomColors = false;
        warningColor = "";
      };
      templates = {
        activeTemplates = [ ];
        enableUserTheming = false;
      };
      ui = {
        boxBorderEnabled = false;
        fontDefault = "Noto Sans";
        fontDefaultScale = 1;
        fontFixed = "JetBrainsMono Nerd Font";
        fontFixedScale = 1;
        panelBackgroundOpacity = 0.98;
        panelsAttachedToBar = false;
        settingsPanelMode = "detached";
        settingsPanelSideBarCardStyle = false;
        tooltipsEnabled = true;
      };
      wallpaper = {
        automationEnabled = false;
        directory = "${homeDir}/nixdots/assets/wallpapers";
        enableMultiMonitorDirectories = false;
        enabled = true;
        favorites = [ ];
        fillColor = "#000000";
        fillMode = "crop";
        hideWallpaperFilenames = true;
        monitorDirectories = [ ];
        overviewBlur = 0.6;
        overviewEnabled = true;
        overviewTint = 0.6;
        panelPosition = "follow_bar";
        randomIntervalSec = 300;
        setWallpaperOnAllMonitors = true;
        showHiddenFiles = false;
        skipStartupTransition = true;
        solidColor = "#1a1a2e";
        sortOrder = "name";
        transitionDuration = 1500;
        transitionEdgeSmoothness = 0.05;
        transitionType = "honeycomb";
        useSolidColor = false;
        useWallhaven = false;
        viewMode = "single";
        wallhavenApiKey = "";
        wallhavenCategories = "110";
        wallhavenOrder = "desc";
        wallhavenPurity = "100";
        wallhavenQuery = "Red kaiju";
        wallhavenRatios = "";
        wallhavenResolutionHeight = "";
        wallhavenResolutionMode = "atleast";
        wallhavenResolutionWidth = "";
        wallhavenSorting = "favorites";
        wallpaperChangeMode = "random";
      };
    };
  };
}
