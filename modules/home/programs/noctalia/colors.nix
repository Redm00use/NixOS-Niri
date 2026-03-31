{ config }:
let
  rofi = {
    mainBg = "#24273a";
    mainFg = "#cdd6f4";
    mainBr = "#b4befe";
    mainEx = "#f5e0dc";
    selectBg = "#b4befe";
    selectFg = "#11111b";
  };
in
{
  mError = rofi.mainEx;
  mHover = rofi.selectBg;
  mOnError = rofi.selectFg;
  mOnHover = rofi.selectFg;
  mOnPrimary = rofi.selectFg;
  mOnSecondary = rofi.selectFg;
  mOnSurface = rofi.mainFg;
  mOnSurfaceVariant = rofi.mainBr;
  mOnTertiary = rofi.selectFg;
  mOutline = rofi.mainBr;
  mPrimary = rofi.mainBr;
  mSecondary = rofi.mainEx;
  mShadow = rofi.mainBg;
  mSurface = rofi.mainBg;
  mSurfaceVariant = rofi.mainBg;
  mTertiary = rofi.mainEx;
}
