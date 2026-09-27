{ config, lib, pkgs, ... }:

# Battery / power management for the ASUS Zenbook 14 (UX3405CA),
# Intel Core Ultra 7 255H. TLP drives everything; thermald (enabled in
# configuration.nix) stays alongside it to handle Intel thermal offsets.
{
  # Plasma pulls in power-profiles-daemon, which is mutually exclusive with TLP
  # (NixOS asserts if both are on). We manage power entirely through TLP.
  services.power-profiles-daemon.enable = lib.mkForce false;

  powerManagement.enable = true;

  services.tlp = {
    enable = true;
    settings = {
      # --- CPU: intel_pstate in active/HWP mode ------------------------------
      # intel_pstate only exposes powersave/performance governors; the Energy
      # Performance Preference (EPP) does the real efficiency-vs-speed biasing.
      CPU_SCALING_GOVERNOR_ON_AC = "powersave";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

      # Turbo + HWP dynamic boost: full speed on AC, capped on battery. Cutting
      # turbo on battery is the single biggest idle/light-load saving on
      # Meteor/Arrow Lake — plug in for osu!/Steam if you need the headroom.
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 0;
      CPU_HWP_DYN_BOOST_ON_AC = 1;
      CPU_HWP_DYN_BOOST_ON_BAT = 0;

      # ASUS firmware platform profile (choices: quiet / balanced / performance).
      PLATFORM_PROFILE_ON_AC = "balanced";
      PLATFORM_PROFILE_ON_BAT = "quiet";

      # --- PCIe / device runtime power management ----------------------------
      # Lets NVMe, Wi-Fi, etc. drop to low-power states when idle (they were
      # stuck 'on' before).
      RUNTIME_PM_ON_AC = "auto";
      RUNTIME_PM_ON_BAT = "auto";
      PCIE_ASPM_ON_AC = "default";
      PCIE_ASPM_ON_BAT = "powersave";

      # --- USB autosuspend (input devices stay awake automatically) ----------
      USB_AUTOSUSPEND = 1;

      # --- Wi-Fi (iwlwifi) power save: only on battery -----------------------
      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "on";

      # --- Audio codec power save --------------------------------------------
      SOUND_POWER_SAVE_ON_AC = 0;
      SOUND_POWER_SAVE_ON_BAT = 1;

      # Disable the NMI watchdog timer — only useful for kernel debugging, and
      # it forces a periodic wakeup on every core.
      NMI_WATCHDOG = 0;

      # --- Battery longevity -------------------------------------------------
      # Stop charging at 90%. ASUS firmware only supports the stop threshold
      # (there is no start threshold), so we set that alone.
      STOP_CHARGE_THRESH_BAT0 = 90;
    };
  };

  # powertop is here for diagnostics only. Do NOT enable its auto-tune service
  # (powerManagement.powertop.enable) — it fights TLP over runtime PM.
  environment.systemPackages = [ pkgs.powertop ];
}
